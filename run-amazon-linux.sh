#!/bin/bash

# Docker container for testing on Amazon Linux 2023

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
CONTAINER_NAME="benchmark-amazon-linux"

echo "=== Amazon Linux 2023 Docker Environment ==="
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
  echo "Error: Docker is not installed."
  echo "Please install Docker first: https://docs.docker.com/get-docker/"
  exit 1
fi

# Stop and remove existing container if it exists
if docker ps -a | grep -q "$CONTAINER_NAME"; then
  echo "Removing existing container..."
  docker stop "$CONTAINER_NAME" 2>/dev/null || true
  docker rm "$CONTAINER_NAME" 2>/dev/null || true
fi

echo "Starting Amazon Linux 2023 container..."
echo ""

# Run the container
docker run -it \
  --name "$CONTAINER_NAME" \
  --hostname "benchmark-server" \
  -v "$PROJECT_ROOT:/workspace:rw" \
  -w /workspace \
  -p 3001-3009:3001-3009 \
  --rm \
  amazonlinux:2023 \
  /bin/bash -c "
    echo '==================================='
    echo 'Welcome to Amazon Linux 2023'
    echo '==================================='
    echo ''
    echo 'Project mounted at: /workspace'
    echo 'Exposed ports: 3001-3009'
    echo ''
    echo 'To set up and start servers:'
    echo '  ./scripts/setup-server.sh'
    echo '  ./scripts/start-servers.sh'
    echo ''
    echo 'Or for a quick start:'
    echo '  yum update -y && yum install -y git'
    echo '  ./scripts/install-server-deps.sh'
    echo '  ./start-servers.sh'
    echo ''
    echo '==================================='
    echo ''
    exec /bin/bash
  "

echo ""
echo "Container stopped."