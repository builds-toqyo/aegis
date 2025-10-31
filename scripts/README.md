# Aegis Yield Scripts

Automation scripts for deployment, testing, and running the Aegis Yield system.

## 📜 Available Scripts

### Setup

**`setup.sh`** - Initial setup for the entire monorepo
```bash
./scripts/setup.sh
```

This script:
- Checks for required dependencies (Foundry, Go, Python)
- Installs Solidity dependencies via Foundry
- Downloads Go modules
- Sets up Python virtual environment
- Creates `.env` from template

### Deployment

**`deploy-contracts.sh`** - Deploy smart contracts to Base
```bash
./scripts/deploy-contracts.sh [network]

# Examples:
./scripts/deploy-contracts.sh base-testnet
./scripts/deploy-contracts.sh base
```

### Running Services

**`start-keeper.sh`** - Start the keeper bot
```bash
./scripts/start-keeper.sh
```

**`start-ml-service.sh`** - Start the ML API service
```bash
./scripts/start-ml-service.sh
```

**`start-api.sh`** - Start the REST API service
```bash
./scripts/start-api.sh
```

### Testing

**`test-all.sh`** - Run all tests across the monorepo
```bash
./scripts/test-all.sh
```

## 🔧 Making Scripts Executable

```bash
chmod +x scripts/*.sh
```

## 📝 Notes

- All scripts should be run from the project root directory
- Scripts automatically load environment variables from `.env`
- Ensure all prerequisites are installed before running setup

## 🚀 Quick Start

```bash
# 1. Make scripts executable
chmod +x scripts/*.sh

# 2. Run setup
./scripts/setup.sh

# 3. Configure environment
nano .env

# 4. Deploy contracts
./scripts/deploy-contracts.sh base-testnet

# 5. Start services
./scripts/start-keeper.sh &
./scripts/start-ml-service.sh &
```
