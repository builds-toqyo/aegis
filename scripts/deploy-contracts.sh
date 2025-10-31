#!/bin/bash

# Deploy Aegis Yield contracts to Base
# Usage: ./scripts/deploy-contracts.sh [network]

set -e

NETWORK=${1:-base-testnet}

echo "🚀 Deploying Aegis Yield contracts to $NETWORK..."

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Navigate to contracts directory
cd contracts

# Install dependencies if needed
if [ ! -d "lib" ]; then
    echo "📦 Installing Foundry dependencies..."
    forge install OpenZeppelin/openzeppelin-contracts-upgradeable
    forge install OpenZeppelin/openzeppelin-contracts
    forge install smartcontractkit/chainlink
    forge install foundry-rs/forge-std
fi

# Build contracts
echo "🔨 Building contracts..."
forge build

# Run tests
echo "🧪 Running tests..."
forge test

# Deploy
echo "📡 Deploying to $NETWORK..."
forge script script/Deploy.s.sol:Deploy \
    --rpc-url $NETWORK \
    --broadcast \
    --verify \
    --slow

echo "✅ Deployment complete!"
