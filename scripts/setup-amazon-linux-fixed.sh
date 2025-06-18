#!/bin/bash
set -e

echo "=== Setting up Amazon Linux 2023 for Image Server Benchmark ==="

# Detect architecture
ARCH=$(uname -m)
echo "Detected architecture: $ARCH"

# Determine actual user home directory
if [ "$EUID" -eq 0 ]; then
    INSTALL_HOME="/root"
else
    INSTALL_HOME="${HOME:-$(eval echo ~$USER)}"
fi
echo "Installing to home directory: $INSTALL_HOME"

# Update system
echo ""
echo "Updating system packages..."
dnf update -y

# Install development tools
echo ""
echo "Installing development tools..."
dnf groupinstall -y "Development Tools"
dnf install -y git wget tar gzip which htop vim tmux tree jq lsof

# Install Node.js 20.x
echo ""
echo "Installing Node.js 20.x..."
dnf install -y nodejs20 nodejs20-npm
ln -sf /usr/bin/node20 /usr/bin/node 2>/dev/null || true
ln -sf /usr/bin/npm20 /usr/bin/npm 2>/dev/null || true

# Install Go
echo ""
echo "Installing Go 1.21..."
GO_VERSION="1.21.5"
if [ "$ARCH" = "aarch64" ]; then
  GO_ARCH="arm64"
else
  GO_ARCH="amd64"
fi
wget -q "https://go.dev/dl/go${GO_VERSION}.linux-${GO_ARCH}.tar.gz"
tar -C /usr/local -xzf "go${GO_VERSION}.linux-${GO_ARCH}.tar.gz"
rm "go${GO_VERSION}.linux-${GO_ARCH}.tar.gz"

# Install Rust (with proper home directory)
echo ""
echo "Installing Rust to $INSTALL_HOME..."
export CARGO_HOME="$INSTALL_HOME/.cargo"
export RUSTUP_HOME="$INSTALL_HOME/.rustup"
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal --default-toolchain stable

# Install Bun (with proper home directory)
echo ""
echo "Installing Bun to $INSTALL_HOME..."
export BUN_INSTALL="$INSTALL_HOME/.bun"
curl -fsSL https://bun.sh/install | bash

# Create shell profile for persistent PATH
cat > /etc/profile.d/benchmark.sh << 'EOF'
# Go
export PATH=/usr/local/go/bin:$PATH
export GOPATH=$HOME/go
export PATH=$GOPATH/bin:$PATH

# Rust
if [ -f "$HOME/.cargo/env" ]; then
  source "$HOME/.cargo/env"
fi

# Bun
if [ -d "$HOME/.bun" ]; then
  export BUN_INSTALL="$HOME/.bun"
  export PATH="$BUN_INSTALL/bin:$PATH"
fi

# Node.js aliases for Amazon Linux
if command -v node20 >/dev/null 2>&1 && ! command -v node >/dev/null 2>&1; then
  alias node=node20
  alias npm=npm20
fi
EOF

# Create proper symlinks with absolute paths
echo ""
echo "Creating symlinks for immediate use..."
ln -sf /usr/local/go/bin/go /usr/local/bin/go 2>/dev/null || true
ln -sf /usr/local/go/bin/gofmt /usr/local/bin/gofmt 2>/dev/null || true

# Only create Rust/Bun symlinks if they were installed successfully
if [ -f "$INSTALL_HOME/.cargo/bin/rustc" ]; then
  ln -sf "$INSTALL_HOME/.cargo/bin/rustc" /usr/local/bin/rustc 2>/dev/null || true
  ln -sf "$INSTALL_HOME/.cargo/bin/cargo" /usr/local/bin/cargo 2>/dev/null || true
  ln -sf "$INSTALL_HOME/.cargo/bin/rustup" /usr/local/bin/rustup 2>/dev/null || true
fi

if [ -f "$INSTALL_HOME/.bun/bin/bun" ]; then
  ln -sf "$INSTALL_HOME/.bun/bin/bun" /usr/local/bin/bun 2>/dev/null || true
fi

# Set up environment for current session
export PATH=/usr/local/go/bin:$PATH
export GOPATH="$INSTALL_HOME/go"
export PATH="$GOPATH/bin:$PATH"
[ -f "$INSTALL_HOME/.cargo/env" ] && source "$INSTALL_HOME/.cargo/env"
export BUN_INSTALL="$INSTALL_HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Install server dependencies (if in project directory)
if [ -d "/workspace" ]; then
  echo ""
  echo "Installing server dependencies..."
  cd /workspace
  
  # TypeScript servers
  cd servers/common && npm install
  cd ../typescript/fastify && npm install
  cd ../hono && npm install
  if command -v bun &> /dev/null; then
    cd ../elysia && bun install
  fi
  
  # Build servers
  echo ""
  echo "Building servers..."
  cd /workspace
  
  # Clean and build
  make clean
  make build-release
fi

# Verify installations
echo ""
echo "=== Setup Complete! ==="
echo ""
echo "Installed versions:"
echo -n "  Node.js: "; node --version 2>/dev/null || echo "Not found"
echo -n "  npm: "; npm --version 2>/dev/null || echo "Not found"
echo -n "  Go: "; go version 2>/dev/null || echo "Not found"
echo -n "  Rust: "; rustc --version 2>/dev/null || echo "Not found"
echo -n "  Cargo: "; cargo --version 2>/dev/null || echo "Not found"
echo -n "  Bun: "; bun --version 2>/dev/null || echo "Not found"

# Show PATH debugging info
echo ""
echo "PATH check:"
echo "  Current PATH: $PATH"
echo "  Go location: $(which go 2>/dev/null || echo 'not in PATH')"
echo "  Cargo location: $(which cargo 2>/dev/null || echo 'not in PATH')"
echo "  Bun location: $(which bun 2>/dev/null || echo 'not in PATH')"

echo ""
echo "Installation locations:"
echo "  Go: /usr/local/go"
echo "  Rust: $INSTALL_HOME/.cargo"
echo "  Bun: $INSTALL_HOME/.bun"

echo ""
echo "To ensure tools are available in new sessions:"
echo "  1. Log out and log back in, or"
echo "  2. Run: source /etc/profile.d/benchmark.sh"
echo ""
echo "If tools are still not found, check if /usr/local/bin is in your PATH"