#!/bin/bash

# Docker container for testing on Amazon Linux 2023 with pre-installed dependencies

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
CONTAINER_NAME="benchmark-amazon-linux-prebuilt"
IMAGE_NAME="benchmark-amazonlinux:latest"

echo "=== Amazon Linux 2023 Docker Environment (Pre-built) ==="
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
  echo "Error: Docker is not installed."
  echo "Please install Docker first: https://docs.docker.com/get-docker/"
  exit 1
fi

# Build the image if it doesn't exist or if --build flag is passed
if [ "$1" = "--build" ] || ! docker images | grep -q "benchmark-amazonlinux"; then
  echo "Building Docker image with all dependencies..."
  docker build -f Dockerfile.amazonlinux -t "$IMAGE_NAME" .
fi

# Stop and remove existing container if it exists
if docker ps -a | grep -q "$CONTAINER_NAME"; then
  echo "Removing existing container..."
  docker stop "$CONTAINER_NAME" 2>/dev/null || true
  docker rm "$CONTAINER_NAME" 2>/dev/null || true
fi

echo "Starting Amazon Linux 2023 container with pre-installed dependencies..."
echo ""

# Run the container
docker run -it \
  --name "$CONTAINER_NAME" \
  --hostname "benchmark-server" \
  -v "$PROJECT_ROOT:/workspace:rw" \
  -w /workspace \
  -p 3001-3009:3001-3009 \
  --rm \
  "$IMAGE_NAME"

echo ""
echo "Container stopped."