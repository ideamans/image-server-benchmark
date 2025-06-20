#!/bin/bash
set -e

echo "============================================================"
echo "   Amazon Linux 2023 - Complete Setup Script"
echo "============================================================"
echo ""
echo "This script will set up everything needed for:"
echo "  - Running servers (./start-servers.sh)"
echo "  - Running benchmarks (./run-benchmark.sh)"
echo ""
echo "Starting setup..."

# Detect architecture
ARCH=$(uname -m)
echo "Detected architecture: $ARCH"

# Update system
echo ""
echo "Updating system packages..."
dnf update -y

# Install development tools
echo ""
echo "Installing development tools..."
dnf groupinstall -y "Development Tools"
dnf install -y git wget tar gzip which htop vim tmux tree jq lsof

# Install libraries needed for Rust compilation
echo ""
echo "Installing libraries for Rust builds..."
# OpenSSL is required for many Rust crates
dnf install -y openssl-devel pkg-config
# Additional common dependencies for Rust projects
dnf install -y perl-core zlib-devel

# Install Node.js
echo ""
echo "Installing Node.js..."

# Method 1: Try Amazon Linux 2023 nodejs package
if ! command -v node &> /dev/null; then
    echo "Attempting to install Node.js from Amazon Linux repos..."
    
    # First, let's see what's available
    echo "Checking available Node.js packages..."
    dnf list available nodejs* 2>/dev/null | grep nodejs || true
    
    # Try different package names
    if dnf install -y nodejs npm 2>/dev/null; then
        echo "Successfully installed nodejs and npm"
    elif dnf install -y nodejs20 nodejs20-npm 2>/dev/null; then
        echo "Successfully installed nodejs20 and nodejs20-npm"
        # Create symlinks
        [ -f /usr/bin/node20 ] && ln -sf /usr/bin/node20 /usr/bin/node
        [ -f /usr/bin/npm20 ] && ln -sf /usr/bin/npm20 /usr/bin/npm
    else
        echo "Amazon Linux packages not found, using NodeSource repository..."
        
        # Method 2: Use NodeSource repository
        curl -fsSL https://rpm.nodesource.com/setup_20.x | bash -
        dnf install -y nodejs
    fi
fi

# Double-check npm is available
if ! command -v npm &> /dev/null; then
    echo "npm not found, attempting separate installation..."
    dnf install -y npm || echo "Warning: npm installation failed"
fi

# Verify Node.js and npm are installed
if ! command -v node &> /dev/null; then
    echo "ERROR: Node.js installation failed!"
    echo "Please check /var/log/dnf.log for details"
    exit 1
fi

if ! command -v npm &> /dev/null; then
    echo "WARNING: npm not found, trying to install via Node.js..."
    # Sometimes npm comes with node but isn't in PATH
    if [ -f /usr/lib/node_modules/npm/bin/npm-cli.js ]; then
        ln -sf /usr/bin/node /usr/local/bin/node
        cat > /usr/local/bin/npm << 'EOF'
#!/bin/sh
exec /usr/bin/node /usr/lib/node_modules/npm/bin/npm-cli.js "$@"
EOF
        chmod +x /usr/local/bin/npm
    else
        echo "ERROR: npm installation failed!"
        exit 1
    fi
fi

echo "Node.js installed: $(node --version)"
echo "npm installed: $(npm --version)"

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
export PATH=/usr/local/go/bin:$PATH

# Install Rust
echo ""
echo "Installing Rust..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal --default-toolchain stable
source "$HOME/.cargo/env"

# Install Bun
echo ""
echo "Installing Bun..."
curl -fsSL https://bun.sh/install | bash
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

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
EOF

# Also create symlinks for immediate availability
echo ""
echo "Creating symlinks for immediate use..."

# Go binaries (these are installed system-wide)
ln -sf /usr/local/go/bin/go /usr/local/bin/go 2>/dev/null || true
ln -sf /usr/local/go/bin/gofmt /usr/local/bin/gofmt 2>/dev/null || true

# Rust binaries (find the actual installation location)
CARGO_HOME="${CARGO_HOME:-$HOME/.cargo}"
if [ -d "$CARGO_HOME/bin" ]; then
    echo "Creating symlinks for Rust tools from $CARGO_HOME/bin..."
    for tool in rustc cargo rustup; do
        if [ -f "$CARGO_HOME/bin/$tool" ]; then
            ln -sf "$CARGO_HOME/bin/$tool" "/usr/local/bin/$tool" 2>/dev/null || true
        fi
    done
else
    echo "Warning: Cargo bin directory not found at $CARGO_HOME/bin"
fi

# Bun binary (find the actual installation location)
BUN_INSTALL="${BUN_INSTALL:-$HOME/.bun}"
if [ -f "$BUN_INSTALL/bin/bun" ]; then
    echo "Creating symlink for Bun from $BUN_INSTALL/bin/bun..."
    ln -sf "$BUN_INSTALL/bin/bun" /usr/local/bin/bun 2>/dev/null || true
else
    echo "Warning: Bun not found at $BUN_INSTALL/bin/bun"
fi

# Install k6 for benchmarking
echo ""
echo "Installing k6 for benchmarking..."
if ! command -v k6 &> /dev/null; then
    # Install k6 from rpm repository
    dnf install -y https://dl.k6.io/rpm/repo.rpm
    dnf install -y k6
else
    echo "k6 is already installed"
fi

# Install server dependencies
echo ""
echo "Installing server dependencies..."

# Determine the working directory
if [ -d "/workspace" ]; then
    WORK_DIR="/workspace"
elif [ -d "$HOME/image-server-benchmark" ]; then
    WORK_DIR="$HOME/image-server-benchmark"
elif [ -d "./servers" ]; then
    WORK_DIR="."
else
    echo "Error: Could not find the project directory"
    exit 1
fi

echo "Using work directory: $WORK_DIR"
cd "$WORK_DIR"

# Install common dependencies first
echo "Installing common module dependencies..."
cd servers/common && npm install
cd "$WORK_DIR"

# Install TypeScript server dependencies
echo "Installing TypeScript server dependencies..."
cd servers/typescript/fastify && npm install
cd "$WORK_DIR"
cd servers/typescript/hono && npm install
cd "$WORK_DIR"
if command -v bun &> /dev/null; then
  cd servers/typescript/elysia && bun install
  cd "$WORK_DIR"
fi

# Install k6 dependencies
echo ""
echo "Installing k6 script dependencies..."
cd k6 && npm install
cd "$WORK_DIR"

# Build servers
echo ""
echo "Building servers..."
cd "$WORK_DIR"

# Ensure all tools are in PATH for the build
export PATH=/usr/local/go/bin:$PATH
export GOPATH=$HOME/go
export PATH=$GOPATH/bin:$PATH
source "$HOME/.cargo/env" 2>/dev/null || true
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Clean and build
make clean
make build-release

# Verify everything is ready
echo ""
echo "=== Setup Complete! ==="
echo ""
echo "Installed versions:"
echo "  Node.js: $(node --version 2>/dev/null || echo 'Not found')"
echo "  npm: $(npm --version 2>/dev/null || echo 'Not found')"
echo "  Go: $(go version 2>/dev/null || echo 'Not found')"
echo "  Rust: $(rustc --version 2>/dev/null || echo 'Not found')"
echo "  Bun: $(bun --version 2>/dev/null || echo 'Not found')"
echo "  k6: $(k6 version 2>/dev/null || echo 'Not found')"
echo ""
echo "Everything is ready!"
echo ""
echo "To run as SERVER:"
echo "  ./start-servers.sh"
echo ""
echo "To run as CLIENT:"
echo "  # First, set SERVER_IP in .env file"
echo "  echo \"SERVER_IP=<server-ip>\" >> .env"
echo "  ./run-benchmark.sh"
echo ""
echo "Note: If you exit and re-enter the container, run:"
echo "  source /etc/profile.d/benchmark.sh"