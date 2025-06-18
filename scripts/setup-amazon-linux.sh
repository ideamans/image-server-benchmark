#!/bin/bash
set -e

echo "=== Setting up Amazon Linux 2023 for Image Server Benchmark ==="

# Update system
echo "Updating system packages..."
yum update -y

# Install basic tools
echo "Installing basic tools..."
# curl is often pre-installed or conflicts with curl-minimal, so we check first
if ! command -v curl &> /dev/null; then
  yum install -y curl || yum install -y curl-minimal
fi

yum install -y \
  git \
  wget \
  tar \
  gzip \
  which \
  make \
  gcc \
  gcc-c++ \
  htop \
  vim \
  tmux \
  tree \
  jq

# Install Node.js 20.x
echo ""
echo "Installing Node.js 20.x..."
curl -fsSL https://rpm.nodesource.com/setup_20.x | bash -
yum install -y nodejs

# Install Go
echo ""
echo "Installing Go 1.21..."
wget -q https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz
rm go1.21.5.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
export PATH=$PATH:/usr/local/go/bin

# Install Rust
echo ""
echo "Installing Rust..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"
echo 'source "$HOME/.cargo/env"' >> /etc/profile

# Install Bun
echo ""
echo "Installing Bun..."
curl -fsSL https://bun.sh/install | bash
export PATH="$HOME/.bun/bin:$PATH"
echo 'export PATH="$HOME/.bun/bin:$PATH"' >> /etc/profile

# Verify installations
echo ""
echo "=== Verifying installations ==="
echo "Node.js: $(node --version)"
echo "npm: $(npm --version)"
echo "Go: $(go version)"
echo "Rust: $(rustc --version)"
echo "Bun: $(bun --version)"

echo ""
echo "=== Setup complete! ==="
echo ""
echo "Next steps:"
echo "1. Install server dependencies: ./scripts/install-server-deps.sh"
echo "2. Start servers: ./start-servers.sh"
echo ""
echo "Or run the full setup: ./scripts/setup-server.sh"