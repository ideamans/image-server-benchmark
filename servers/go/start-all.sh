#!/bin/bash

# Script to start all Go servers

echo "Starting all Go servers..."
echo "========================="

# Kill any existing Go server processes
echo "Stopping any existing servers..."
pkill -f "fiber-server" 2>/dev/null
pkill -f "gin-server" 2>/dev/null
pkill -f "echo-server" 2>/dev/null
sleep 2

# Build all servers
echo "Building servers..."
make build

if [ $? -ne 0 ]; then
    echo "Build failed!"
    exit 1
fi

# Start servers in background
echo
echo "Starting servers..."

cd fiber && ./fiber-server &
FIBER_PID=$!
echo "Fiber server started (PID: $FIBER_PID)"

cd ../gin && ./gin-server &
GIN_PID=$!
echo "Gin server started (PID: $GIN_PID)"

cd ../echo && ./echo-server &
ECHO_PID=$!
echo "Echo server started (PID: $ECHO_PID)"

cd ..

# Wait a moment for servers to start
sleep 3

# Run tests
echo
echo "Running health checks..."
./test-servers.sh

# Create PID file for easy cleanup
echo "$FIBER_PID $GIN_PID $ECHO_PID" > .server-pids

echo
echo "All servers started!"
echo "To stop servers, run: ./stop-all.sh"