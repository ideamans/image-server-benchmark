#!/bin/bash

echo "=== Fixing PATH environment for Go, Rust, and Bun ==="

# Check if we're root or regular user
if [ "$EUID" -eq 0 ]; then
    echo "Running as root"
    USER_HOME="/root"
else
    echo "Running as user: $USER"
    USER_HOME="$HOME"
fi

# Go path
if [ -d "/usr/local/go" ]; then
    export PATH="/usr/local/go/bin:$PATH"
    export GOPATH="$USER_HOME/go"
    export PATH="$GOPATH/bin:$PATH"
    echo "✓ Go path configured: $(which go 2>/dev/null || echo 'go not found')"
else
    echo "✗ Go not found at /usr/local/go"
fi

# Rust path
if [ -f "$USER_HOME/.cargo/env" ]; then
    source "$USER_HOME/.cargo/env"
    echo "✓ Rust path configured: $(which cargo 2>/dev/null || echo 'cargo not found')"
else
    echo "✗ Rust not found at $USER_HOME/.cargo"
fi

# Bun path
if [ -d "$USER_HOME/.bun" ]; then
    export BUN_INSTALL="$USER_HOME/.bun"
    export PATH="$BUN_INSTALL/bin:$PATH"
    echo "✓ Bun path configured: $(which bun 2>/dev/null || echo 'bun not found')"
else
    echo "✗ Bun not found at $USER_HOME/.bun"
fi

echo ""
echo "Current PATH: $PATH"
echo ""
echo "Checking tool availability:"
echo "  go: $(command -v go >/dev/null 2>&1 && echo '✓ Found' || echo '✗ Not found')"
echo "  cargo: $(command -v cargo >/dev/null 2>&1 && echo '✓ Found' || echo '✗ Not found')"
echo "  rustc: $(command -v rustc >/dev/null 2>&1 && echo '✓ Found' || echo '✗ Not found')"
echo "  bun: $(command -v bun >/dev/null 2>&1 && echo '✓ Found' || echo '✗ Not found')"
echo ""

# Test if we can build Go servers
if command -v go >/dev/null 2>&1; then
    echo "Testing Go build..."
    cd "$(dirname "$0")"
    make clean
    make build
    echo "✓ Go build test completed"
else
    echo "✗ Cannot test Go build - go command not found"
fi

echo ""
echo "To make these changes permanent, add the following to your shell profile:"
echo ""
echo "# Go"
echo "export PATH=\"/usr/local/go/bin:\$PATH\""
echo "export GOPATH=\"\$HOME/go\""
echo "export PATH=\"\$GOPATH/bin:\$PATH\""
echo ""
echo "# Rust"
echo "[ -f \"\$HOME/.cargo/env\" ] && source \"\$HOME/.cargo/env\""
echo ""
echo "# Bun"
echo "export BUN_INSTALL=\"\$HOME/.bun\""
echo "export PATH=\"\$BUN_INSTALL/bin:\$PATH\""