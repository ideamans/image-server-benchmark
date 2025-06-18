#!/bin/bash

# Get the project root directory
PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"

echo "Starting all benchmark servers..."

# Kill any existing servers on our ports
for port in {3001..3009}; do
  lsof -ti:$port | xargs kill -9 2>/dev/null || true
done

# Build all servers first
echo "Building all servers..."
(cd "$PROJECT_ROOT/servers" && make build-release)

# Start TypeScript servers
echo ""
echo "Starting TypeScript servers..."
echo "- Starting Fastify..."
(cd "$PROJECT_ROOT/servers/typescript/fastify" && make run > /tmp/fastify.log 2>&1) &

echo "- Starting Hono..."
(cd "$PROJECT_ROOT/servers/typescript/hono" && make run > /tmp/hono.log 2>&1) &

echo "- Starting Elysia..."
if command -v bun &> /dev/null; then
  (cd "$PROJECT_ROOT/servers/typescript/elysia" && make run > /tmp/elysia.log 2>&1) &
else
  echo "  Warning: Bun not installed, skipping Elysia"
  echo "Bun not installed" > /tmp/elysia.log
fi

# Start Go servers
echo ""
echo "Starting Go servers..."
echo "- Starting Fiber..."
(cd "$PROJECT_ROOT/servers/go/fiber" && ./fiber-server > /tmp/fiber.log 2>&1) &

echo "- Starting Gin..."
(cd "$PROJECT_ROOT/servers/go/gin" && ./gin-server > /tmp/gin.log 2>&1) &

echo "- Starting Echo..."
(cd "$PROJECT_ROOT/servers/go/echo" && ./echo-server > /tmp/echo.log 2>&1) &

# Start Rust servers
echo ""
echo "Starting Rust servers..."
echo "- Starting Actix..."
(cd "$PROJECT_ROOT/servers/rust/actix" && cargo run --release > /tmp/actix.log 2>&1) &

echo "- Starting Axum..."
(cd "$PROJECT_ROOT/servers/rust/axum" && cargo run --release > /tmp/axum.log 2>&1) &

echo "- Starting Rocket..."
(cd "$PROJECT_ROOT/servers/rust/rocket" && cargo run --release > /tmp/rocket.log 2>&1) &

echo ""
echo "Waiting for servers to start..."
sleep 10

echo ""
echo "Testing all servers..."
echo "===================="

# Define servers and their ports
declare -a servers=(
  "TypeScript/Fastify:3001"
  "TypeScript/Hono:3002"
)

# Add Elysia only if bun is available
if command -v bun &> /dev/null; then
  servers+=("TypeScript/Elysia:3003")
fi

servers+=(
  "Go/Fiber:3004"
  "Go/Gin:3005"
  "Go/Echo:3006"
  "Rust/Actix:3007"
  "Rust/Axum:3008"
  "Rust/Rocket:3009"
)

# Test endpoints - health is optional, others are required
required_endpoints=("/local/20k")
optional_endpoints=("/health" "/proxy/20k")
failed_servers=()
all_success=true

# Test each server
for server_info in "${servers[@]}"; do
  IFS=':' read -r server_name port <<< "$server_info"
  echo ""
  echo "Testing $server_name (port $port)..."
  
  server_ok=true
  critical_failure=false
  
  # Test required endpoints
  for endpoint in "${required_endpoints[@]}"; do
    url="http://localhost:${port}${endpoint}"
    response=$(curl -s -o /dev/null -w "%{http_code}" --max-time 3 "$url" 2>/dev/null || echo "000")
    
    if [ "$response" = "200" ]; then
      echo "  ✓ ${endpoint}"
    else
      echo "  ✗ ${endpoint} (HTTP $response) - URL: $url"
      critical_failure=true
      all_success=false
    fi
  done
  
  # Test optional endpoints
  for endpoint in "${optional_endpoints[@]}"; do
    url="http://localhost:${port}${endpoint}"
    response=$(curl -s -o /dev/null -w "%{http_code}" --max-time 3 "$url" 2>/dev/null || echo "000")
    
    if [ "$response" = "200" ]; then
      echo "  ✓ ${endpoint}"
    elif [ "$response" = "404" ] && [ "$endpoint" = "/health" ]; then
      echo "  ⚠ ${endpoint} (not implemented)"
    else
      echo "  ⚠ ${endpoint} (HTTP $response)"
      if [ "$endpoint" != "/health" ]; then
        server_ok=false
      fi
    fi
  done
  
  if [ "$critical_failure" = true ]; then
    failed_servers+=("$server_name")
  fi
done

echo ""
echo "===================="

if [ "$all_success" = true ]; then
  echo "✅ All servers are running successfully!"
  echo ""
  echo "Server logs are available at:"
  echo "  TypeScript: /tmp/fastify.log, /tmp/hono.log, /tmp/elysia.log"
  echo "  Go: /tmp/fiber.log, /tmp/gin.log, /tmp/echo.log"
  echo "  Rust: /tmp/actix.log, /tmp/axum.log, /tmp/rocket.log"
else
  echo "❌ Some servers failed to start properly:"
  for failed in "${failed_servers[@]}"; do
    echo "  - $failed"
  done
  echo ""
  echo "Checking server logs for errors..."
  
  # Show last few lines of failed server logs
  for failed in "${failed_servers[@]}"; do
    log_name=$(echo "$failed" | awk -F'/' '{print tolower($2)}')
    log_file="/tmp/${log_name}.log"
    if [ -f "$log_file" ]; then
      echo ""
      echo "Last 5 lines from $log_file:"
      tail -5 "$log_file"
    fi
  done
  
  echo ""
  echo "Stopping all servers due to failures..."
  "$PROJECT_ROOT/stop-servers.sh"
  echo ""
  echo "Please fix the issues and try again."
  exit 1
fi