#!/bin/bash

echo "Testing TypeScript servers..."

# Test if images exist
if [ ! -f "../../images/20k.jpg" ] || [ ! -f "../../images/50k.jpg" ] || [ ! -f "../../images/100k.jpg" ]; then
    echo "Error: Test images not found in images directory"
    echo "Please run the generate-images.sh script first"
    exit 1
fi

# Function to test server endpoints
test_server() {
    local server_name=$1
    local port=$2
    
    echo "Testing $server_name server on port $port..."
    
    # Health check
    response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$port/health)
    if [ "$response" = "200" ]; then
        echo "✓ Health check passed"
    else
        echo "✗ Health check failed (HTTP $response)"
        return 1
    fi
    
    # Test local endpoints
    for size in 20k 50k 100k; do
        response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$port/local/$size)
        if [ "$response" = "200" ]; then
            echo "✓ /local/$size endpoint passed"
        else
            echo "✗ /local/$size endpoint failed (HTTP $response)"
        fi
    done
    
    echo ""
}

# Start servers
echo "Starting servers..."
cd fastify && npm install && npm start &
FASTIFY_PID=$!
sleep 3

cd ../hono && npm install && npm start &
HONO_PID=$!
sleep 3

if command -v bun &> /dev/null; then
    cd ../elysia && bun install && bun start &
    ELYSIA_PID=$!
    sleep 3
else
    echo "Bun not installed, skipping Elysia server"
    ELYSIA_PID=""
fi

# Test servers
sleep 2
test_server "Fastify" 3001
test_server "Hono" 3002
if [ ! -z "$ELYSIA_PID" ]; then
    test_server "Elysia" 3003
fi

# Cleanup
echo "Stopping servers..."
kill $FASTIFY_PID $HONO_PID $ELYSIA_PID 2>/dev/null
wait

echo "Test complete!"