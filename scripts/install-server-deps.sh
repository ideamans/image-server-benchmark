#!/bin/bash
set -e

# Get the project root directory
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "Installing server dependencies..."

# Install common module dependencies
echo ""
echo "Installing common module dependencies..."
cd "$PROJECT_ROOT/servers/common"
npm install

# Install TypeScript server dependencies
echo ""
echo "Installing TypeScript server dependencies..."

echo "- Fastify"
cd "$PROJECT_ROOT/servers/typescript/fastify"
npm install

echo "- Hono"
cd "$PROJECT_ROOT/servers/typescript/hono"
npm install

echo "- Elysia"
if command -v bun &> /dev/null; then
  cd "$PROJECT_ROOT/servers/typescript/elysia"
  bun install
else
  echo "  Warning: Bun not installed, skipping Elysia"
fi

# Go dependencies are handled by go.mod
echo ""
echo "Go dependencies will be installed during build..."

# Rust dependencies are handled by Cargo.toml
echo ""
echo "Rust dependencies will be installed during build..."

echo ""
echo "Dependencies installation complete!"