#!/bin/bash
# Source this file to set up the environment for building and running servers
# Usage: source ./setup-env.sh

echo "=== Setting up environment for Image Server Benchmark ==="

# Determine the correct home directory
if [ "$EUID" -eq 0 ]; then
    USER_HOME="/root"
else
    USER_HOME="${HOME:-$(eval echo ~$USER)}"
fi

# Go
if [ -d "/usr/local/go" ]; then
    export PATH="/usr/local/go/bin:$PATH"
    export GOPATH="$USER_HOME/go"
    export PATH="$GOPATH/bin:$PATH"
    echo "✓ Go configured: $(go version 2>/dev/null || echo 'go not found')"
fi

# Rust
if [ -f "$USER_HOME/.cargo/env" ]; then
    source "$USER_HOME/.cargo/env"
    echo "✓ Rust configured: $(rustc --version 2>/dev/null || echo 'rustc not found')"
fi

# Bun
if [ -d "$USER_HOME/.bun" ]; then
    export BUN_INSTALL="$USER_HOME/.bun"
    export PATH="$BUN_INSTALL/bin:$PATH"
    echo "✓ Bun configured: $(bun --version 2>/dev/null || echo 'bun not found')"
fi

# Node.js (Amazon Linux specific)
if command -v node20 >/dev/null 2>&1 && ! command -v node >/dev/null 2>&1; then
    alias node=node20
    alias npm=npm20
    echo "✓ Node.js aliases configured"
fi

echo ""
echo "Environment setup complete. You can now build and run the servers."