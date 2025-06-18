#!/bin/bash

echo "=== Rust Dependencies Check for Amazon Linux 2023 ==="
echo ""

# Check for OpenSSL
echo "OpenSSL packages:"
echo "  openssl version: $(openssl version 2>/dev/null || echo 'Not installed')"
echo "  openssl-devel: $(dnf list installed openssl-devel 2>/dev/null | grep openssl-devel || echo 'Not installed')"
echo ""

# Check for pkg-config
echo "pkg-config:"
echo "  version: $(pkg-config --version 2>/dev/null || echo 'Not installed')"
echo ""

# Check OpenSSL pkg-config files
echo "OpenSSL pkg-config files:"
if command -v pkg-config &> /dev/null; then
    echo "  openssl: $(pkg-config --modversion openssl 2>/dev/null || echo 'Not found')"
    echo "  openssl libs: $(pkg-config --libs openssl 2>/dev/null || echo 'Not found')"
else
    echo "  pkg-config not installed"
fi
echo ""

# Check environment variables that Rust might need
echo "Environment variables for Rust OpenSSL:"
echo "  OPENSSL_DIR: ${OPENSSL_DIR:-Not set}"
echo "  OPENSSL_LIB_DIR: ${OPENSSL_LIB_DIR:-Not set}"
echo "  OPENSSL_INCLUDE_DIR: ${OPENSSL_INCLUDE_DIR:-Not set}"
echo "  PKG_CONFIG_PATH: ${PKG_CONFIG_PATH:-Not set}"
echo ""

# Check for OpenSSL headers
echo "OpenSSL header files:"
for header in /usr/include/openssl/ssl.h /usr/include/openssl/crypto.h; do
    if [ -f "$header" ]; then
        echo "  $header: Found"
    else
        echo "  $header: Not found"
    fi
done
echo ""

# Suggest fixes
echo "If you're having OpenSSL issues with Rust, try:"
echo "  1. Install missing packages:"
echo "     dnf install -y openssl-devel pkg-config perl-core"
echo ""
echo "  2. Set environment variables (if needed):"
echo "     export OPENSSL_DIR=/usr"
echo "     export PKG_CONFIG_PATH=/usr/lib64/pkgconfig:/usr/lib/pkgconfig"
echo ""
echo "  3. For vendored OpenSSL (alternative):"
echo "     Add to Cargo.toml: openssl = { version = \"*\", features = [\"vendored\"] }"