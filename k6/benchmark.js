import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';
import { textSummary } from 'https://jslib.k6.io/k6-summary/0.0.1/index.js';

// Custom metrics
const errorRate = new Rate('errors');
const imageLoadTime = new Trend('image_load_time', true);

// Get test configuration from environment variables
const SERVER_IP = __ENV.SERVER_IP || 'localhost';
const SERVER_PORT = parseInt(__ENV.CURRENT_SERVER_PORT || '3001');
const ENDPOINT = __ENV.CURRENT_ENDPOINT || '/local/20k';
const TEST_NAME = __ENV.TEST_NAME || 'test';

// Parse durations
const WARMUP_DURATION = __ENV.BENCHMARK_WARMUP_DURATION || '10s';
const MAIN_DURATION = __ENV.BENCHMARK_DURATION || '60s';
const COOLDOWN_DURATION = __ENV.BENCHMARK_COOLDOWN_DURATION || '10s';
const MAX_VUS = parseInt(__ENV.MAX_VUS || '200');
const ERROR_THRESHOLD = parseFloat(__ENV.ERROR_THRESHOLD || '0.01');
const RESPONSE_TIME_THRESHOLD = parseInt(__ENV.RESPONSE_TIME_THRESHOLD || '1000');

// Test configuration
export const options = {
  scenarios: {
    benchmark: {
      executor: 'ramping-vus',
      startVUs: 1,
      stages: [
        { duration: WARMUP_DURATION, target: Math.min(10, MAX_VUS) }, // Warmup
        { duration: MAIN_DURATION, target: MAX_VUS },                 // Main test
        { duration: COOLDOWN_DURATION, target: 0 },                   // Cooldown
      ],
      gracefulRampDown: '30s',
    },
  },
  thresholds: {
    'http_req_failed': [`rate<${ERROR_THRESHOLD}`],
    'http_req_duration': [`p(95)<${RESPONSE_TIME_THRESHOLD}`],
    'errors': [`rate<${ERROR_THRESHOLD}`],
  },
  // Keep response bodies for validation
  // discardResponseBodies: true,
  // Set timeout
  timeout: '30s',
};

// Main test function
export default function () {
  const url = `http://${SERVER_IP}:${SERVER_PORT}${ENDPOINT}`;
  
  const params = {
    headers: {
      'Accept': 'image/jpeg',
      'Connection': 'keep-alive',
    },
    timeout: '30s',
    compression: 'gzip',
  };
  
  const startTime = new Date();
  const response = http.get(url, params);
  const endTime = new Date();
  
  // Record custom metrics
  const loadTime = endTime - startTime;
  imageLoadTime.add(loadTime);
  
  // Check response
  const checks = check(response, {
    'status is 200': (r) => r.status === 200,
    'content type is image': (r) => {
      const contentType = r.headers['Content-Type'] || r.headers['content-type'];
      return contentType && contentType.includes('image/');
    },
    'response has body': (r) => r.body && r.body.length > 0,
    'response time OK': (r) => r.timings.duration < RESPONSE_TIME_THRESHOLD,
  });
  
  // Only count as error if status is not 200
  const isError = response.status !== 200;
  errorRate.add(isError);
  
  // Small pause between requests to avoid overwhelming the server
  sleep(0.01);
}

// Custom summary handler
export function handleSummary(data) {
  const customData = {
    test_name: TEST_NAME,
    server_ip: SERVER_IP,
    server_port: SERVER_PORT,
    endpoint: ENDPOINT,
    max_vus: MAX_VUS,
    duration: MAIN_DURATION,
    timestamp: new Date().toISOString(),
  };
  
  // Merge custom data with k6 metrics
  const result = {
    ...customData,
    metrics: data.metrics,
  };
  
  // Console output
  console.log('\n=== Test Summary ===');
  console.log(`Test: ${TEST_NAME}`);
  console.log(`Endpoint: http://${SERVER_IP}:${SERVER_PORT}${ENDPOINT}`);
  console.log(`Max VUs: ${MAX_VUS}`);
  console.log(`Duration: ${MAIN_DURATION}`);
  
  if (data.metrics.http_reqs && data.metrics.http_reqs.values) {
    console.log(`\nTotal Requests: ${data.metrics.http_reqs.values.count || 0}`);
    console.log(`RPS: ${data.metrics.http_reqs.values.rate ? data.metrics.http_reqs.values.rate.toFixed(2) : 'N/A'}`);
  }
  
  if (data.metrics.http_req_duration) {
    const duration = data.metrics.http_req_duration.values;
    console.log(`\nResponse Time:`);
    console.log(`  Avg: ${duration.avg ? duration.avg.toFixed(2) : 'N/A'}ms`);
    console.log(`  P95: ${duration['p(95)'] ? duration['p(95)'].toFixed(2) : 'N/A'}ms`);
    console.log(`  P99: ${duration['p(99)'] ? duration['p(99)'].toFixed(2) : 'N/A'}ms`);
  }
  
  if (data.metrics.http_req_failed && data.metrics.http_req_failed.values) {
    const errorRate = data.metrics.http_req_failed.values.rate || 0;
    console.log(`\nError Rate: ${(errorRate * 100).toFixed(2)}%`);
  }
  
  // Save results to JSON file
  const jsonOutput = `/tmp/k6-result-${TEST_NAME.replace(/\//g, '-')}.json`;
  
  return {
    [jsonOutput]: JSON.stringify(result, null, 2),
    'stdout': textSummary(data, { indent: ' ', enableColors: true }),
  };
}