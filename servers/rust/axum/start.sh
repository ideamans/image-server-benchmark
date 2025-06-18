#!/bin/bash

# Load environment variables
cd "$(dirname "$0")/../../.."
if [ -f .env ]; then
  export $(cat .env | grep -v '^#' | xargs)
fi

cd servers/rust/axum
cargo run --release