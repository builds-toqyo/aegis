#!/bin/bash

# Start the Aegis Yield keeper bot
# Usage: ./scripts/start-keeper.sh

set -e

echo "🤖 Starting Aegis Yield Keeper Bot..."

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Navigate to backend directory
cd backend

# Install dependencies if needed
if [ ! -f "go.sum" ]; then
    echo "📦 Installing Go dependencies..."
    go mod download
fi

# Build keeper bot
echo "🔨 Building keeper bot..."
go build -o bin/keeper ./keeper-bot

# Run keeper bot
echo "🚀 Starting keeper bot..."
./bin/keeper
