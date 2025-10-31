#!/bin/bash

# Generate Go bindings from Solidity contracts
# This script uses abigen to create Go wrappers for contract interaction

set -e

echo "🔧 Generating Go bindings for Aegis Yield contracts..."

# Directories
CONTRACTS_DIR="contracts"
OUT_DIR="backend/web3-client/bindings"
ARTIFACTS_DIR="$CONTRACTS_DIR/out"

# Create output directory
mkdir -p $OUT_DIR

# Check if abigen is installed
if ! command -v abigen &> /dev/null; then
    echo "❌ abigen not found. Installing..."
    go install github.com/ethereum/go-ethereum/cmd/abigen@latest
fi

# Build contracts first
echo "📦 Building contracts with Foundry..."
cd $CONTRACTS_DIR
forge build
cd ..

# Generate bindings for AegisController
echo "🔨 Generating AegisController bindings..."
abigen --abi=$ARTIFACTS_DIR/AegisController.sol/AegisController.json \
    --bin=$ARTIFACTS_DIR/AegisController.sol/AegisController.bin \
    --pkg=bindings \
    --type=AegisController \
    --out=$OUT_DIR/aegis_controller.go

# Generate bindings for AegisVault
echo "🔨 Generating AegisVault bindings..."
abigen --abi=$ARTIFACTS_DIR/AegisVault.sol/AegisVault.json \
    --bin=$ARTIFACTS_DIR/AegisVault.sol/AegisVault.bin \
    --pkg=bindings \
    --type=AegisVault \
    --out=$OUT_DIR/aegis_vault.go

# Generate bindings for StrategyAaveBase
echo "🔨 Generating StrategyAaveBase bindings..."
abigen --abi=$ARTIFACTS_DIR/StrategyAaveBase.sol/StrategyAaveBase.json \
    --bin=$ARTIFACTS_DIR/StrategyAaveBase.sol/StrategyAaveBase.bin \
    --pkg=bindings \
    --type=StrategyAaveBase \
    --out=$OUT_DIR/strategy_aave.go

echo "✅ Go bindings generated successfully in $OUT_DIR/"
echo ""
echo "Generated files:"
ls -lh $OUT_DIR/
