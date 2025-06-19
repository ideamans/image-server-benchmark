#!/bin/bash

# Load environment variables from .env file
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ENV_FILE="$PROJECT_ROOT/.env"

if [ -f "$ENV_FILE" ]; then
  # Export variables from .env file
  export $(cat "$ENV_FILE" | grep -v '^#' | grep -v '^$' | xargs)
  echo "Loaded environment variables from $ENV_FILE"
else
  echo "Warning: .env file not found at $ENV_FILE"
fi

# Set default values if not already set
: ${ORIGIN_URL_BASE:="http://localhost:8080/"}
: ${SERVER_START_PORT:=3001}
: ${SERVER_WORKER_THREADS:=0}
: ${SERVER_IP:=""}
: ${BENCHMARK_DURATION:="60s"}
: ${BENCHMARK_WARMUP_DURATION:="10s"}
: ${BENCHMARK_COOLDOWN_DURATION:="10s"}
: ${MAX_VUS:=200}
: ${ERROR_THRESHOLD:=0.01}
: ${RESPONSE_TIME_THRESHOLD:=1000}
: ${AWS_REGION:="us-east-1"}
: ${SERVER_INSTANCE_TYPE:="m7a.medium"}
: ${CLIENT_INSTANCE_TYPE:="m7i.4xlarge"}
: ${AUTO_SHUTDOWN_MINUTES:=180}

# Export all variables
export ORIGIN_URL_BASE SERVER_START_PORT SERVER_WORKER_THREADS
export SERVER_IP BENCHMARK_DURATION BENCHMARK_WARMUP_DURATION
export BENCHMARK_COOLDOWN_DURATION MAX_VUS ERROR_THRESHOLD
export RESPONSE_TIME_THRESHOLD AWS_REGION
export SERVER_INSTANCE_TYPE CLIENT_INSTANCE_TYPE AUTO_SHUTDOWN_MINUTES