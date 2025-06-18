#!/bin/bash
set -e

echo "=== Building Go Servers ==="

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Try to find Go in common locations
GO_PATHS=(
    "/usr/local/go/bin/go"
    "/usr/bin/go"
    "/opt/go/bin/go"
    "$HOME/go/bin/go"
    "$(which go 2>/dev/null || true)"
)

GO_CMD=""
for path in "${GO_PATHS[@]}"; do
    if [ -x "$path" ]; then
        GO_CMD="$path"
        break
    fi
done

if [ -z "$GO_CMD" ]; then
    echo "Error: Go not found. Please install Go or ensure it's in your PATH."
    echo ""
    echo "You can:"
    echo "1. Run: source ./setup-env.sh"
    echo "2. Or install Go manually"
    exit 1
fi

echo "Using Go at: $GO_CMD"
echo "Go version: $($GO_CMD version)"
echo ""

# Set GOPATH if not set
export GOPATH="${GOPATH:-$HOME/go}"
export GO111MODULE=on

# Build each server
SERVERS=(fiber gin echo)

for server in "${SERVERS[@]}"; do
    echo "Building $server server..."
    cd "$SCRIPT_DIR/$server"
    
    # Download dependencies
    echo "  - Downloading dependencies..."
    $GO_CMD mod download
    
    # Build the server
    echo "  - Building binary..."
    $GO_CMD build -o "${server}-server" .
    
    if [ -f "${server}-server" ]; then
        echo "  ✓ Successfully built $server-server"
        chmod +x "${server}-server"
    else
        echo "  ✗ Failed to build $server-server"
        exit 1
    fi
    echo ""
done

echo "=== Build Complete ==="
echo ""
echo "Built servers:"
for server in "${SERVERS[@]}"; do
    if [ -f "$SCRIPT_DIR/$server/${server}-server" ]; then
        echo "  ✓ $server-server"
    else
        echo "  ✗ $server-server (missing)"
    fi
done

echo ""
echo "To start all servers, run: ./start-all.sh"