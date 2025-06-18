#!/bin/bash

# Test health endpoints for all Rust servers
# This script assumes the servers are running on their default ports

source "$(dirname "$0")/utils/load-env.sh"

# Default to localhost if SERVER_IP is not set
TEST_HOST="${SERVER_IP:-localhost}"
BASE_PORT="${SERVER_START_PORT:-3001}"

echo "Testing health endpoints on ${TEST_HOST}..."
echo "Base port: ${BASE_PORT}"
echo

# Calculate ports for Rust servers
ACTIX_PORT=$((BASE_PORT + 6))
AXUM_PORT=$((BASE_PORT + 7))
ROCKET_PORT=$((BASE_PORT + 8))

# Test Actix health endpoint
echo "Testing Actix server (port ${ACTIX_PORT})..."
curl -s -w "\nHTTP Status: %{http_code}\n" "http://${TEST_HOST}:${ACTIX_PORT}/health" || echo "Failed to connect"
echo

# Test Axum health endpoint
echo "Testing Axum server (port ${AXUM_PORT})..."
curl -s -w "\nHTTP Status: %{http_code}\n" "http://${TEST_HOST}:${AXUM_PORT}/health" || echo "Failed to connect"
echo

# Test Rocket health endpoint
echo "Testing Rocket server (port ${ROCKET_PORT})..."
curl -s -w "\nHTTP Status: %{http_code}\n" "http://${TEST_HOST}:${ROCKET_PORT}/health" || echo "Failed to connect"
echo

echo "Health endpoint tests completed."