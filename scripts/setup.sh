#!/bin/bash

# Setup script for Aegis Yield monorepo
# Usage: ./scripts/setup.sh

set -e

echo "🏗️  Setting up Aegis Yield monorepo..."

# Check prerequisites
echo "Checking prerequisites..."

# Check Foundry
if ! command -v forge &> /dev/null; then
    echo "❌ Foundry not found. Please install from https://getfoundry.sh"
    exit 1
fi
echo "✅ Foundry installed"

# Check Go
if ! command -v go &> /dev/null; then
    echo "❌ Go not found. Please install from https://go.dev"
    exit 1
fi
echo "✅ Go installed"

# Check Python
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 not found. Please install Python 3.10+"
    exit 1
fi
echo "✅ Python installed"

# Setup contracts
echo ""
echo "📜 Setting up Solidity contracts..."
cd contracts
forge install OpenZeppelin/openzeppelin-contracts-upgradeable
forge install OpenZeppelin/openzeppelin-contracts
forge install smartcontractkit/chainlink
forge install foundry-rs/forge-std
forge build
cd ..

# Setup backend
echo ""
echo "🖥️  Setting up Go backend..."
cd backend
go mod download
cd ..

# Setup ML engine
echo ""
echo "🧠 Setting up ML engine..."
cd ml-engine
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
deactivate
cd ..

# Create .env if it doesn't exist
if [ ! -f .env ]; then
    echo ""
    echo "📝 Creating .env file..."
    cp .env.example .env
    echo "⚠️  Please update .env with your configuration"
fi

echo ""
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Update .env with your configuration"
echo "2. Deploy contracts: ./scripts/deploy-contracts.sh"
echo "3. Start keeper bot: ./scripts/start-keeper.sh"
echo "4. Start ML service: ./scripts/start-ml-service.sh"
