#!/bin/bash

echo "=== PATH Diagnostics ==="
echo ""
echo "Current user: $(whoami)"
echo "Home directory: $HOME"
echo "Current PATH: $PATH"
echo ""

echo "=== Checking Go ==="
echo "Looking for Go installation..."
for path in /usr/local/go /opt/go /usr/lib/go $HOME/go; do
    if [ -d "$path" ]; then
        echo "  Found Go directory at: $path"
        if [ -f "$path/bin/go" ]; then
            echo "  ✓ go binary exists at $path/bin/go"
            echo "  Version: $($path/bin/go version 2>&1)"
        fi
    fi
done
echo "which go: $(which go 2>&1)"
echo ""

echo "=== Checking Rust ==="
echo "Looking for Rust installation..."
for home in $HOME /root /home/*; do
    if [ -d "$home/.cargo" ]; then
        echo "  Found Cargo directory at: $home/.cargo"
        if [ -f "$home/.cargo/bin/cargo" ]; then
            echo "  ✓ cargo binary exists at $home/.cargo/bin/cargo"
            echo "  Version: $($home/.cargo/bin/cargo --version 2>&1)"
        fi
    fi
done
echo "which cargo: $(which cargo 2>&1)"
echo ""

echo "=== Checking Bun ==="
echo "Looking for Bun installation..."
for home in $HOME /root /home/*; do
    if [ -d "$home/.bun" ]; then
        echo "  Found Bun directory at: $home/.bun"
        if [ -f "$home/.bun/bin/bun" ]; then
            echo "  ✓ bun binary exists at $home/.bun/bin/bun"
            echo "  Version: $($home/.bun/bin/bun --version 2>&1)"
        fi
    fi
done
echo "which bun: $(which bun 2>&1)"
echo ""

echo "=== Checking /usr/local/bin ==="
echo "Contents of /usr/local/bin:"
ls -la /usr/local/bin/ 2>/dev/null | grep -E "(go|cargo|rustc|bun)" || echo "  No go/cargo/rustc/bun found"
echo ""

echo "=== Checking profile.d ==="
if [ -f /etc/profile.d/benchmark.sh ]; then
    echo "✓ /etc/profile.d/benchmark.sh exists"
    echo "Contents:"
    cat /etc/profile.d/benchmark.sh | head -20
else
    echo "✗ /etc/profile.d/benchmark.sh not found"
fi
echo ""

echo "=== Quick Fix Commands ==="
echo "To fix Go path:"
echo "  export PATH=/usr/local/go/bin:\$PATH"
echo ""
echo "To fix Rust path:"
echo "  source \$HOME/.cargo/env"
echo ""
echo "To fix Bun path:"
echo "  export PATH=\$HOME/.bun/bin:\$PATH"
echo ""
echo "To apply all fixes at once:"
echo "  source ./setup-env.sh"