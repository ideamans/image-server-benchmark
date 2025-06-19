#!/bin/bash

echo "Starting Amazon Linux 2023 container..."

# Start the container
docker-compose up -d

# Enter the container
echo ""
echo "Entering container..."
echo "Run: ./setup-amazon-linux.sh"
echo ""
docker-compose exec benchmark-server bash