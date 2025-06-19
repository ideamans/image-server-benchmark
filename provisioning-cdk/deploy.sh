#!/bin/bash
set -e

echo "=== CDK Deployment Script ==="

# Load environment variables from .env file
if [ -f "../.env" ]; then
  echo "Loading configuration from ../.env"
  export $(cat ../.env | grep -v '^#' | xargs)
fi

# Check if AWS_PROFILE is set
if [ -n "$AWS_PROFILE" ]; then
  echo "Using AWS Profile: $AWS_PROFILE"
else
  echo "No AWS_PROFILE specified in .env file"
  echo "Using default AWS credentials"
fi

# Check if KEY_PAIR_NAME is set
if [ -z "$KEY_PAIR_NAME" ]; then
  echo ""
  echo "WARNING: KEY_PAIR_NAME is not set in .env file"
  echo "You will need to provide it as a parameter:"
  echo "  --parameters KeyPairName=your-key-pair"
  echo ""
fi

# Build the project
echo ""
echo "Building CDK project..."
npm run build

# Deploy the stack
echo ""
echo "Deploying stack..."
if [ -z "$KEY_PAIR_NAME" ]; then
  echo "Running: cdk deploy"
  npx cdk deploy
else
  echo "Running: cdk deploy --parameters KeyPairName=$KEY_PAIR_NAME"
  npx cdk deploy --parameters KeyPairName=$KEY_PAIR_NAME
fi