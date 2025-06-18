#!/bin/bash

# Script to stop all Go servers

echo "Stopping all Go servers..."

# Read PIDs from file if exists
if [ -f .server-pids ]; then
    PIDS=$(cat .server-pids)
    for PID in $PIDS; do
        if kill -0 $PID 2>/dev/null; then
            kill $PID
            echo "Stopped server with PID: $PID"
        fi
    done
    rm .server-pids
fi

# Also try to kill by process name as backup
pkill -f "fiber-server" 2>/dev/null
pkill -f "gin-server" 2>/dev/null
pkill -f "echo-server" 2>/dev/null

echo "All servers stopped."