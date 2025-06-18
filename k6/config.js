import { config } from 'dotenv';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));

// Load .env from project root
config({ path: resolve(__dirname, '../.env') });

export const benchmarkConfig = {
  // Server configuration
  serverIp: process.env.SERVER_IP || 'localhost',
  serverStartPort: parseInt(process.env.SERVER_START_PORT || '3001'),
  
  // Benchmark configuration
  duration: process.env.BENCHMARK_DURATION || '60s',
  warmupDuration: process.env.BENCHMARK_WARMUP_DURATION || '10s',
  cooldownDuration: process.env.BENCHMARK_COOLDOWN_DURATION || '10s',
  maxVUs: parseInt(process.env.MAX_VUS || '200'),
  errorThreshold: parseFloat(process.env.ERROR_THRESHOLD || '0.01'),
  responseTimeThreshold: parseInt(process.env.RESPONSE_TIME_THRESHOLD || '1000'),
};

// Server definitions
export const servers = [
  { name: 'Fastify', language: 'TypeScript', port: benchmarkConfig.serverStartPort + 0 },
  { name: 'Hono', language: 'TypeScript', port: benchmarkConfig.serverStartPort + 1 },
  { name: 'Elysia', language: 'TypeScript', port: benchmarkConfig.serverStartPort + 2 },
  { name: 'Fiber', language: 'Go', port: benchmarkConfig.serverStartPort + 3 },
  { name: 'Gin', language: 'Go', port: benchmarkConfig.serverStartPort + 4 },
  { name: 'Echo', language: 'Go', port: benchmarkConfig.serverStartPort + 5 },
  { name: 'Actix', language: 'Rust', port: benchmarkConfig.serverStartPort + 6 },
  { name: 'Axum', language: 'Rust', port: benchmarkConfig.serverStartPort + 7 },
  { name: 'Rocket', language: 'Rust', port: benchmarkConfig.serverStartPort + 8 },
];

// Endpoint definitions
export const endpoints = [
  { path: '/local/20k', type: 'local', size: '20k' },
  { path: '/local/50k', type: 'local', size: '50k' },
  { path: '/local/100k', type: 'local', size: '100k' },
  { path: '/proxy/20k', type: 'proxy', size: '20k' },
  { path: '/proxy/50k', type: 'proxy', size: '50k' },
  { path: '/proxy/100k', type: 'proxy', size: '100k' },
];

// Export configuration for k6
export function getK6Config() {
  return {
    SERVER_IP: benchmarkConfig.serverIp,
    SERVER_START_PORT: benchmarkConfig.serverStartPort.toString(),
    MAX_VUS: benchmarkConfig.maxVUs.toString(),
    BENCHMARK_DURATION: benchmarkConfig.duration,
    BENCHMARK_WARMUP_DURATION: benchmarkConfig.warmupDuration,
    BENCHMARK_COOLDOWN_DURATION: benchmarkConfig.cooldownDuration,
    ERROR_THRESHOLD: benchmarkConfig.errorThreshold.toString(),
    RESPONSE_TIME_THRESHOLD: benchmarkConfig.responseTimeThreshold.toString(),
  };
}

// Validate configuration
export function validateConfig() {
  const errors = [];
  
  if (!benchmarkConfig.serverIp || benchmarkConfig.serverIp === '') {
    errors.push('SERVER_IP is not set in .env file');
  }
  
  if (benchmarkConfig.serverStartPort < 1024 || benchmarkConfig.serverStartPort > 65535) {
    errors.push('SERVER_START_PORT must be between 1024 and 65535');
  }
  
  if (benchmarkConfig.maxVUs < 1 || benchmarkConfig.maxVUs > 10000) {
    errors.push('MAX_VUS must be between 1 and 10000');
  }
  
  if (benchmarkConfig.errorThreshold < 0 || benchmarkConfig.errorThreshold > 1) {
    errors.push('ERROR_THRESHOLD must be between 0 and 1');
  }
  
  return errors;
}

// If run directly, display configuration
if (import.meta.url === `file://${process.argv[1]}`) {
  console.log('Benchmark Configuration:');
  console.log(JSON.stringify(benchmarkConfig, null, 2));
  
  const errors = validateConfig();
  if (errors.length > 0) {
    console.error('\nConfiguration errors:');
    errors.forEach(error => console.error(`- ${error}`));
    process.exit(1);
  } else {
    console.log('\nConfiguration is valid.');
  }
}