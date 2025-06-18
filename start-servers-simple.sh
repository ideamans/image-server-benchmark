#!/bin/bash

# Simple server startup script - starts only TypeScript servers for testing

# Get the project root directory
PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"

echo "Starting TypeScript servers only (for quick testing)..."

# Kill any existing servers on TypeScript ports
for port in {3001..3003}; do
  lsof -ti:$port | xargs kill -9 2>/dev/null || true
done

# Start TypeScript servers
echo "- Starting Fastify (port 3001)..."
(cd "$PROJECT_ROOT/servers/typescript/fastify" && npm start > /tmp/fastify.log 2>&1) &

echo "- Starting Hono (port 3002)..."
(cd "$PROJECT_ROOT/servers/typescript/hono" && npm start > /tmp/hono.log 2>&1) &

echo "- Starting Elysia (port 3003)..."
if command -v bun &> /dev/null; then
  (cd "$PROJECT_ROOT/servers/typescript/elysia" && bun start > /tmp/elysia.log 2>&1) &
else
  echo "  Bun not installed, skipping Elysia"
fi

echo ""
echo "Waiting for servers to start..."
sleep 5

echo ""
echo "Testing servers..."
for port in 3001 3002 3003; do
  if curl -s -o /dev/null -w "%{http_code}" --max-time 2 "http://localhost:${port}/health" | grep -q "200"; then
    echo "✓ Server on port $port is running"
  else
    echo "✗ Server on port $port is not responding"
  fi
done

echo ""
echo "Server logs available at: /tmp/fastify.log, /tmp/hono.log, /tmp/elysia.log"