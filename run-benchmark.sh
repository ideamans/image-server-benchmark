#!/bin/bash
set -e

echo "=== Image Server Benchmark ==="

# Load environment variables
source "$(dirname "$0")/scripts/utils/load-env.sh"

# Change to project root
cd "$PROJECT_ROOT"

# Check if SERVER_IP is set
if [ -z "$SERVER_IP" ]; then
  echo "SERVER_IP is not set in .env file"
  read -p "Enter server IP address: " SERVER_IP
  
  # Save to .env file
  echo "SERVER_IP=$SERVER_IP" >> "$ENV_FILE"
  echo "SERVER_IP saved to .env file"
fi

# Validate k6 is installed
if ! command -v k6 &> /dev/null; then
  echo "k6 is not installed. Please run ./scripts/setup-client.sh first."
  exit 1
fi

# Display configuration
echo ""
echo "Benchmark Configuration:"
echo "  Server IP: $SERVER_IP"
echo "  Port Range: ${SERVER_START_PORT}-$((SERVER_START_PORT + 8))"
echo "  Max VUs: $MAX_VUS"
echo "  Test Duration: $BENCHMARK_DURATION"
echo "  Warmup: $BENCHMARK_WARMUP_DURATION"
echo "  Cooldown: $BENCHMARK_COOLDOWN_DURATION"
echo "  Error Threshold: ${ERROR_THRESHOLD}"
echo "  Response Time Threshold: ${RESPONSE_TIME_THRESHOLD}ms"
echo ""

# Confirm before starting
read -p "Start benchmark? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Benchmark cancelled."
  exit 0
fi

# Run the benchmark
echo ""
echo "Starting benchmark..."
cd "$PROJECT_ROOT/k6"

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
  echo "Installing k6 dependencies..."
  npm install
fi

# Execute benchmark
node run-benchmark.js

echo ""
echo "Benchmark complete!"
echo ""
echo "Results saved to:"
echo "  - $PROJECT_ROOT/results/benchmark-results.tsv"
echo "  - $PROJECT_ROOT/results/benchmark-results-detailed.json"