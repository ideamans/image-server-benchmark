import { spawn } from 'child_process';
import { benchmarkConfig, servers, endpoints, getK6Config, validateConfig } from './config.js';
import { ResultFormatter } from './result-formatter.js';
import fs from 'fs';
import path from 'path';

// Validate configuration
const configErrors = validateConfig();
if (configErrors.length > 0) {
  console.error('Configuration errors:');
  configErrors.forEach(error => console.error(`- ${error}`));
  process.exit(1);
}

console.log('=== Image Server Benchmark ===');
console.log(`Server IP: ${benchmarkConfig.serverIp}`);
console.log(`Max VUs: ${benchmarkConfig.maxVUs}`);
console.log(`Duration: ${benchmarkConfig.duration}`);
console.log(`Starting benchmark...\n`);

// Result formatter
const formatter = new ResultFormatter();

// Function to run k6 test
async function runK6Test(server, endpoint) {
  const testName = `${server.name}-${server.language}-${endpoint.size}-${endpoint.type}`;
  console.log(`\n--- Testing ${testName} ---`);
  console.log(`URL: http://${benchmarkConfig.serverIp}:${server.port}${endpoint.path}`);
  
  return new Promise((resolve, reject) => {
    const env = {
      ...process.env,
      ...getK6Config(),
      CURRENT_SERVER_PORT: server.port.toString(),
      CURRENT_ENDPOINT: endpoint.path,
      TEST_NAME: testName,
    };
    
    const k6Process = spawn('k6', ['run', path.join(import.meta.url.replace('file://', ''), '../benchmark.js')], {
      env,
      stdio: 'inherit',
    });
    
    k6Process.on('close', (code) => {
      if (code === 0) {
        // Add result to formatter
        const resultPath = `/tmp/k6-result-${testName.replace(/\//g, '-')}.json`;
        if (fs.existsSync(resultPath)) {
          formatter.addResult(testName, resultPath);
        }
        resolve();
      } else {
        console.error(`k6 exited with code ${code}`);
        resolve(); // Continue even if one test fails
      }
    });
    
    k6Process.on('error', (error) => {
      console.error(`Failed to start k6: ${error}`);
      resolve(); // Continue even if one test fails
    });
  });
}

// Function to check if server is running
async function checkServer(server) {
  try {
    const response = await fetch(`http://${benchmarkConfig.serverIp}:${server.port}/health`, {
      method: 'GET',
      signal: AbortSignal.timeout(2000),
    });
    return response.ok;
  } catch (error) {
    return false;
  }
}

// Main benchmark execution
async function runBenchmark() {
  const startTime = new Date();
  
  // Test each server
  for (const server of servers) {
    // Check if server is running
    const isRunning = await checkServer(server);
    if (!isRunning) {
      console.log(`\n⚠️  Skipping ${server.name} - server not responding on port ${server.port}`);
      continue;
    }
    
    // Test each endpoint
    for (const endpoint of endpoints) {
      await runK6Test(server, endpoint);
      
      // Cool down between tests
      console.log(`\nCooling down for ${benchmarkConfig.cooldownDuration}...`);
      await new Promise(resolve => setTimeout(resolve, parseDuration(benchmarkConfig.cooldownDuration)));
    }
  }
  
  const endTime = new Date();
  const totalTime = Math.round((endTime - startTime) / 1000);
  
  // Save and display results
  formatter.saveToTSV();
  formatter.printSummary();
  
  console.log(`\n=== Benchmark Complete ===`);
  console.log(`Total time: ${Math.floor(totalTime / 60)}m ${totalTime % 60}s`);
}

// Helper function to parse duration strings
function parseDuration(duration) {
  const match = duration.match(/^(\d+)([smh])$/);
  if (!match) return 10000; // Default 10s
  
  const value = parseInt(match[1]);
  const unit = match[2];
  
  switch (unit) {
    case 's': return value * 1000;
    case 'm': return value * 60 * 1000;
    case 'h': return value * 60 * 60 * 1000;
    default: return 10000;
  }
}

// Check if k6 is installed
const checkK6 = spawn('k6', ['version']);
checkK6.on('error', () => {
  console.error('k6 is not installed. Please install k6 first.');
  console.error('Visit: https://k6.io/docs/getting-started/installation/');
  process.exit(1);
});

checkK6.on('close', (code) => {
  if (code === 0) {
    // Start benchmark
    runBenchmark().catch(console.error);
  }
});