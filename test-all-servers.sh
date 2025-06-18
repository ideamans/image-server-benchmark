#!/bin/bash

echo "====================================="
echo "Image Server Benchmark - Test Script"
echo "====================================="

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Base URL
BASE_URL="http://localhost"

# Test endpoints
endpoints=("local/20k" "local/50k" "local/100k" "proxy/20k" "proxy/50k" "proxy/100k")

# Server configurations
declare -a servers=(
  "TypeScript/Fastify:3001"
  "TypeScript/Hono:3002"
  "TypeScript/Elysia:3003"
  "Go/Fiber:3004"
  "Go/Gin:3005"
  "Go/Echo:3006"
  "Rust/Actix:3007"
  "Rust/Axum:3008"
  "Rust/Rocket:3009"
)

# Function to test a single endpoint
test_endpoint() {
  local server_name=$1
  local port=$2
  local endpoint=$3
  local url="${BASE_URL}:${port}/${endpoint}"
  
  # Use curl with timeout
  response=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$url")
  
  if [ "$response" = "200" ]; then
    echo -e "  ${GREEN}✓${NC} /${endpoint}"
  else
    echo -e "  ${RED}✗${NC} /${endpoint} (HTTP $response)"
  fi
}

# Test each server
for server in "${servers[@]}"; do
  IFS=':' read -r name port <<< "$server"
  echo ""
  echo "Testing $name (port $port)..."
  
  # Test health endpoint first
  health_response=$(curl -s -o /dev/null -w "%{http_code}" --max-time 2 "${BASE_URL}:${port}/health" 2>/dev/null || echo "000")
  
  if [ "$health_response" = "200" ]; then
    echo -e "  ${GREEN}✓${NC} Server is running"
    
    # Test all endpoints
    for endpoint in "${endpoints[@]}"; do
      test_endpoint "$name" "$port" "$endpoint"
    done
  else
    echo -e "  ${RED}✗${NC} Server is not running (health check failed)"
  fi
done

echo ""
echo "====================================="
echo "Test complete!"
echo "====================================="