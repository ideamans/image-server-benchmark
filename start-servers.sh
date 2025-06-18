#!/bin/bash

echo "Starting all benchmark servers..."

# Kill any existing servers on our ports
for port in {3001..3009}; do
  lsof -ti:$port | xargs kill -9 2>/dev/null || true
done

# Start TypeScript servers
echo "Starting TypeScript servers..."
cd servers/typescript/fastify && npm install && npm start &
cd servers/typescript/hono && npm install && npm start &
cd servers/typescript/elysia && bun install && bun start &

# Start Go servers
echo "Starting Go servers..."
cd servers/go && make build
cd servers/go/fiber && ./fiber &
cd servers/go/gin && ./gin &
cd servers/go/echo && ./echo &

# Start Rust servers
echo "Starting Rust servers..."
cd servers/rust && ./build.sh
cd servers/rust/actix && ./start.sh &
cd servers/rust/axum && ./start.sh &
cd servers/rust/rocket && ./start.sh &

echo "Waiting for servers to start..."
sleep 5

echo "All servers should be running. Use ./test-all-servers.sh to verify."