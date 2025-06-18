#!/bin/bash

# Test script for Go servers

echo "Testing Go Image Servers..."
echo "=========================="

# Base port from environment or default
BASE_PORT=${SERVER_START_PORT:-3001}

# Server details
declare -A servers
servers[fiber]=$((BASE_PORT + 3))
servers[gin]=$((BASE_PORT + 4))
servers[echo]=$((BASE_PORT + 5))

# Test endpoints
endpoints=(
    "/health"
    "/local/20k"
    "/local/50k"
    "/local/100k"
    "/proxy/20k"
    "/proxy/50k"
    "/proxy/100k"
)

# Test each server
for server in fiber gin echo; do
    port=${servers[$server]}
    echo
    echo "Testing $server server on port $port..."
    echo "----------------------------------------"
    
    # Check if server is running
    if ! curl -s "http://localhost:$port/health" > /dev/null; then
        echo "❌ $server server is not running on port $port"
        continue
    fi
    
    echo "✅ $server server is running"
    
    # Test each endpoint
    for endpoint in "${endpoints[@]}"; do
        response=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:$port$endpoint")
        if [ "$response" = "200" ]; then
            echo "  ✅ $endpoint - OK"
        else
            echo "  ❌ $endpoint - Failed (HTTP $response)"
        fi
    done
done

echo
echo "Test complete!"