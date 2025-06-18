#!/bin/bash
set -e

echo "=== Setting up Amazon Linux 2023 for Image Server Benchmark ==="

# Detect architecture
ARCH=$(uname -m)
echo "Detected architecture: $ARCH"

# Update system
echo ""
echo "Updating system packages..."
dnf update -y

# Install development tools group
echo ""
echo "Installing development tools..."
dnf groupinstall -y "Development Tools"

# Install additional tools
echo ""
echo "Installing additional tools..."
dnf install -y \
  git \
  wget \
  tar \
  gzip \
  which \
  htop \
  vim \
  tmux \
  tree \
  jq \
  lsof

# Install Node.js 20.x
echo ""
echo "Installing Node.js 20.x..."
dnf install -y nodejs20 nodejs20-npm

# Create symlinks for node and npm if needed
if ! command -v node &> /dev/null; then
  ln -sf /usr/bin/node20 /usr/bin/node
fi
if ! command -v npm &> /dev/null; then
  ln -sf /usr/bin/npm20 /usr/bin/npm
fi

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

# Set up Go environment
cat >> /etc/profile.d/go.sh << 'EOF'
export PATH=$PATH:/usr/local/go/bin
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin
EOF
source /etc/profile.d/go.sh

# Install Rust
echo ""
echo "Installing Rust..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal --default-toolchain stable
source "$HOME/.cargo/env"

# Set up Rust environment for all users
cat >> /etc/profile.d/rust.sh << 'EOF'
if [ -f "$HOME/.cargo/env" ]; then
  source "$HOME/.cargo/env"
fi
EOF

# Install Bun
echo ""
echo "Installing Bun..."
curl -fsSL https://bun.sh/install | bash

# Set up Bun environment
BUN_PATH="$HOME/.bun"
cat >> /etc/profile.d/bun.sh << EOF
export BUN_INSTALL="$BUN_PATH"
export PATH="\$BUN_INSTALL/bin:\$PATH"
EOF
export BUN_INSTALL="$BUN_PATH"
export PATH="$BUN_INSTALL/bin:$PATH"

# Verify installations
echo ""
echo "=== Verifying installations ==="
echo "Node.js: $(node --version 2>/dev/null || echo 'Not found')"
echo "npm: $(npm --version 2>/dev/null || echo 'Not found')"
echo "Go: $(go version 2>/dev/null || echo 'Not found')"
echo "Rust: $(rustc --version 2>/dev/null || echo 'Not found')"
echo "Cargo: $(cargo --version 2>/dev/null || echo 'Not found')"
echo "Bun: $(bun --version 2>/dev/null || echo 'Not found')"

echo ""
echo "=== Setup complete! ==="
echo ""
echo "IMPORTANT: Run 'source /etc/profile' or start a new shell to load all PATH settings"
echo ""
echo "Next steps:"
echo "1. source /etc/profile"
echo "2. cd /workspace"
echo "3. make clean"
echo "4. make build-release"
echo "5. ./start-servers.sh"