#!/bin/bash

# Start the ML API service
# Usage: ./scripts/start-ml-service.sh

set -e

echo "🧠 Starting ML API Service..."

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Navigate to ml-engine directory
cd ml-engine

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo "📦 Creating Python virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
source venv/bin/activate

# Install dependencies
echo "📦 Installing Python dependencies..."
pip install -r requirements.txt

# Start ML service
echo "🚀 Starting ML API service..."
python api/ml_service.py
