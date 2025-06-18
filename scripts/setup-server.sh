#!/bin/bash
set -e

echo "=== Image Server Benchmark - Server Setup ==="

# Load environment variables
source "$(dirname "$0")/utils/load-env.sh"

# Change to project root
cd "$PROJECT_ROOT"

echo "Installing server dependencies..."

# Install common dependencies
echo "Installing common module dependencies..."
cd servers/common
npm install

# TypeScript servers
echo ""
echo "Setting up TypeScript servers..."
cd "$PROJECT_ROOT/servers/typescript"

echo "- Fastify"
cd fastify && npm install && cd ..

echo "- Hono"
cd hono && npm install && cd ..

echo "- Elysia (requires Bun)"
if ! command -v bun &> /dev/null; then
  echo "  Bun not found. Installing Bun..."
  curl -fsSL https://bun.sh/install | bash
  export PATH="$HOME/.bun/bin:$PATH"
fi
cd elysia && bun install && cd ..

# Go servers
echo ""
echo "Setting up Go servers..."
if ! command -v go &> /dev/null; then
  echo "Go not found. Please install Go first."
  echo "Visit: https://golang.org/doc/install"
  exit 1
fi

cd "$PROJECT_ROOT/servers/go"
echo "Building Go servers..."
make build

# Rust servers
echo ""
echo "Setting up Rust servers..."
if ! command -v cargo &> /dev/null; then
  echo "Rust not found. Installing Rust..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  source "$HOME/.cargo/env"
fi

cd "$PROJECT_ROOT/servers/rust"
echo "Building Rust servers..."
./build.sh

# Test images
echo ""
echo "Checking test images..."
cd "$PROJECT_ROOT/images"
if [ ! -f "20k.jpg" ] || [ ! -f "50k.jpg" ] || [ ! -f "100k.jpg" ]; then
  echo "Test images not found. Please ensure 20k.jpg, 50k.jpg, and 100k.jpg exist in the images directory."
  exit 1
else
  echo "Test images found:"
  ls -lh *.jpg
fi

echo ""
echo "=== Server setup complete! ==="
echo ""
echo "To start all servers, run:"
echo "  ./scripts/start-servers.sh"
echo ""
echo "Servers will run on ports ${SERVER_START_PORT}-$((SERVER_START_PORT + 8))"