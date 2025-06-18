#!/bin/bash

echo "Stopping all benchmark servers..."

# Kill servers on all benchmark ports
for port in {3001..3009}; do
  echo "Stopping server on port $port..."
  lsof -ti:$port | xargs kill -9 2>/dev/null || true
done

echo "All servers stopped."