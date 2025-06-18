#!/bin/bash

# Load environment variables
cd "$(dirname "$0")/../../.."
if [ -f .env ]; then
  export $(cat .env | grep -v '^#' | xargs)
fi

cd servers/rust/actix
cargo run --release