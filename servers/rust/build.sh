#!/bin/bash

set -e

echo "Building Rust servers..."

# Build all servers in release mode
cargo build --release

echo "Rust servers built successfully!"
echo ""
echo "Binaries are located at:"
echo "  - target/release/actix-server"
echo "  - target/release/axum-server"
echo "  - target/release/rocket-server"