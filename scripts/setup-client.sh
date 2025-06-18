#!/bin/bash
set -e

echo "=== Image Server Benchmark - Client Setup ==="

# Load environment variables
source "$(dirname "$0")/utils/load-env.sh"

# Change to project root
cd "$PROJECT_ROOT"

# Check if SERVER_IP is set
if [ -z "$SERVER_IP" ]; then
  echo "ERROR: SERVER_IP is not set in .env file"
  echo ""
  echo "Please add the server IP address to your .env file:"
  echo "  echo \"SERVER_IP=<server-ip-address>\" >> .env"
  echo ""
  exit 1
fi

echo "Server IP: $SERVER_IP"

# Install k6
echo ""
echo "Checking k6 installation..."
if ! command -v k6 &> /dev/null; then
  echo "k6 not found. Installing k6..."
  
  # Detect OS
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    if command -v dnf &> /dev/null; then
      # RHEL/Fedora/Amazon Linux
      sudo dnf install -y https://dl.k6.io/rpm/repo.rpm
      sudo dnf install -y k6
    elif command -v apt-get &> /dev/null; then
      # Debian/Ubuntu
      sudo gpg -k
      sudo gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
      echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list
      sudo apt-get update
      sudo apt-get install k6
    else
      echo "Unsupported Linux distribution. Please install k6 manually."
      echo "Visit: https://k6.io/docs/getting-started/installation/"
      exit 1
    fi
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    if command -v brew &> /dev/null; then
      brew install k6
    else
      echo "Homebrew not found. Please install k6 manually."
      echo "Visit: https://k6.io/docs/getting-started/installation/"
      exit 1
    fi
  else
    echo "Unsupported OS. Please install k6 manually."
    echo "Visit: https://k6.io/docs/getting-started/installation/"
    exit 1
  fi
else
  echo "k6 is already installed:"
  k6 version
fi

# Install Node.js dependencies for k6 scripts
echo ""
echo "Installing k6 script dependencies..."
cd "$PROJECT_ROOT/k6"
npm install

# Test connectivity to server
echo ""
echo "Testing connectivity to server..."
for port in $(seq $SERVER_START_PORT $((SERVER_START_PORT + 8))); do
  if curl -s -o /dev/null -w "%{http_code}" --max-time 2 "http://${SERVER_IP}:${port}/health" | grep -q "200"; then
    echo "✓ Server responding on port $port"
  else
    echo "✗ No response on port $port"
  fi
done

echo ""
echo "=== Client setup complete! ==="
echo ""
echo "Configuration:"
echo "  Server IP: $SERVER_IP"
echo "  Max VUs: $MAX_VUS"
echo "  Test Duration: $BENCHMARK_DURATION"
echo "  Warmup Duration: $BENCHMARK_WARMUP_DURATION"
echo "  Cooldown Duration: $BENCHMARK_COOLDOWN_DURATION"
echo ""
echo "To run the benchmark:"
echo "  ./scripts/run-benchmark.sh"
echo ""
echo "Or to test a specific server:"
echo "  cd k6"
echo "  k6 run -e SERVER_IP=$SERVER_IP -e CURRENT_SERVER_PORT=3001 -e CURRENT_ENDPOINT=/local/20k benchmark.js"