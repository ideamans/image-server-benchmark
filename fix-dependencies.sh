#!/bin/bash

# Get the project root directory
PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"

echo "Fixing dependencies..."

# Fix Hono dependencies
echo ""
echo "Fixing Hono server dependencies..."
cd "$PROJECT_ROOT/servers/typescript/hono"
rm -rf node_modules package-lock.json
npm install

# Install Bun for Elysia (if not installed)
if ! command -v bun &> /dev/null; then
  echo ""
  echo "Installing Bun for Elysia..."
  curl -fsSL https://bun.sh/install | bash
  export PATH="$HOME/.bun/bin:$PATH"
  echo 'export PATH="$HOME/.bun/bin:$PATH"' >> ~/.bashrc
  echo 'export PATH="$HOME/.bun/bin:$PATH"' >> ~/.zshrc
fi

# Fix proxy issues - update .env if needed
echo ""
echo "Checking proxy configuration..."
if grep -q "ORIGIN_URL_BASE" "$PROJECT_ROOT/.env"; then
  echo "ORIGIN_URL_BASE is already set"
else
  if grep -q "ORIGIN_URL" "$PROJECT_ROOT/.env"; then
    echo "Adding ORIGIN_URL_BASE based on ORIGIN_URL..."
    echo "ORIGIN_URL_BASE=$(grep ORIGIN_URL "$PROJECT_ROOT/.env" | cut -d'=' -f2-)" >> "$PROJECT_ROOT/.env"
  fi
fi

echo ""
echo "Dependencies fixed!"
echo ""
echo "Note: If Bun was just installed, you may need to restart your shell or run:"
echo "  export PATH=\"\$HOME/.bun/bin:\$PATH\""