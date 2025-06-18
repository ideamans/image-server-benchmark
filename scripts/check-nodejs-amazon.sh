#!/bin/bash

echo "=== Node.js Package Check for Amazon Linux 2023 ==="
echo ""

# Check what nodejs packages are available
echo "Available Node.js packages:"
dnf list available | grep -E "^nodejs" | head -20

echo ""
echo "Installed Node.js packages:"
dnf list installed | grep -E "nodejs|npm" || echo "No Node.js packages installed"

echo ""
echo "Checking for Node.js binaries:"
echo "  /usr/bin/node: $(ls -la /usr/bin/node 2>/dev/null || echo 'Not found')"
echo "  /usr/bin/node20: $(ls -la /usr/bin/node20 2>/dev/null || echo 'Not found')" 
echo "  /usr/bin/npm: $(ls -la /usr/bin/npm 2>/dev/null || echo 'Not found')"
echo "  /usr/bin/npm20: $(ls -la /usr/bin/npm20 2>/dev/null || echo 'Not found')"

echo ""
echo "PATH check:"
echo "  which node: $(which node 2>/dev/null || echo 'Not in PATH')"
echo "  which npm: $(which npm 2>/dev/null || echo 'Not in PATH')"

echo ""
echo "Alternative Node.js installation method (if needed):"
echo "  # Using NodeSource repository:"
echo "  curl -fsSL https://rpm.nodesource.com/setup_20.x | bash -"
echo "  dnf install -y nodejs"