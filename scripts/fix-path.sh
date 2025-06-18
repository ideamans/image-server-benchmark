#!/bin/bash

echo "=== PATH Diagnostic and Fix Script ==="
echo ""
echo "Current PATH: $PATH"
echo ""

# Check and fix Go
echo "Checking Go..."
if ! command -v go &> /dev/null; then
    if [ -f /usr/local/go/bin/go ]; then
        echo "  Found Go at /usr/local/go/bin/go"
        export PATH=/usr/local/go/bin:$PATH
        echo "  Added to PATH"
    else
        echo "  Go not found in /usr/local/go/bin/"
    fi
else
    echo "  Go is available: $(which go)"
fi

# Check and fix Rust
echo ""
echo "Checking Rust..."
if ! command -v rustc &> /dev/null; then
    if [ -f "$HOME/.cargo/env" ]; then
        echo "  Found Rust environment at $HOME/.cargo/env"
        source "$HOME/.cargo/env"
        echo "  Sourced Rust environment"
    elif [ -f /root/.cargo/env ]; then
        echo "  Found Rust environment at /root/.cargo/env"
        source /root/.cargo/env
        echo "  Sourced Rust environment"
    else
        echo "  Rust environment file not found"
    fi
else
    echo "  Rust is available: $(which rustc)"
fi

# Check and fix Bun
echo ""
echo "Checking Bun..."
if ! command -v bun &> /dev/null; then
    for dir in "$HOME/.bun" "/root/.bun"; do
        if [ -f "$dir/bin/bun" ]; then
            echo "  Found Bun at $dir/bin/bun"
            export PATH="$dir/bin:$PATH"
            echo "  Added to PATH"
            break
        fi
    done
else
    echo "  Bun is available: $(which bun)"
fi

# Final check
echo ""
echo "=== Final Status ==="
echo "Updated PATH: $PATH"
echo ""
echo "Available commands:"
echo "  go: $(which go 2>/dev/null || echo 'Not found')"
echo "  rustc: $(which rustc 2>/dev/null || echo 'Not found')"
echo "  cargo: $(which cargo 2>/dev/null || echo 'Not found')"
echo "  bun: $(which bun 2>/dev/null || echo 'Not found')"
echo ""
echo "To make these changes permanent, add the following to your shell profile:"
echo ""
echo "export PATH=/usr/local/go/bin:\$PATH"
echo "[ -f \"\$HOME/.cargo/env\" ] && source \"\$HOME/.cargo/env\""
echo "[ -d \"\$HOME/.bun\" ] && export PATH=\"\$HOME/.bun/bin:\$PATH\""