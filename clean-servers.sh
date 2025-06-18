#!/bin/bash

# Clean all server build artifacts

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"

echo "=== Cleaning all server build artifacts ==="
echo ""

# Stop any running servers first
if [ -f "$PROJECT_ROOT/stop-servers.sh" ]; then
  echo "Stopping any running servers..."
  "$PROJECT_ROOT/stop-servers.sh"
  echo ""
fi

# Clean using make
echo "Cleaning build artifacts..."
cd "$PROJECT_ROOT/servers"
make clean

echo ""
echo "=== Cleanup complete ==="
echo ""
echo "All build artifacts have been removed."
echo "This ensures clean builds across different platforms (macOS/Linux)."