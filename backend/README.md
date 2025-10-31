# Aegis Yield Backend

High-performance Go backend for the Aegis Yield keeper bot, optimization solver, and API services.

##  Directory Structure

```
backend/
 keeper-bot/          # Keeper bot entry point
    main.go
 web3-client/         # Blockchain interaction layer
    base_connector.go
    contracts.go
 data-aggregator/     # Data collection and aggregation
    aggregator.go
    sources.go
 optimization-solver/ # Portfolio optimization engine
    solver.go
    constraints.go
 api-service/         # REST API endpoints
    api.go
    handlers.go
    middleware.go
 pkg/                 # Shared packages
    config/
    logger/
    utils/
 go.mod
```

##  Getting Started

### Prerequisites

- Go 1.21 or higher
- Access to Base RPC endpoint
- Private key for keeper wallet

### Installation

```bash
# Install dependencies
go mod download

# Build the keeper bot
go build -o bin/keeper ./keeper-bot

# Build the API service
go build -o bin/api ./api-service
```

### Configuration

Copy `.env.example` to `.env` and configure:

```bash
cp ../.env.example .env
```

### Running

```bash
# Run keeper bot
./bin/keeper

# Run API service
./bin/api

# Or run directly with Go
go run keeper-bot/main.go
go run api-service/main.go
```

##  Testing

```bash
# Run all tests
go test ./...

# Run with coverage
go test -cover ./...

# Run specific package tests
go test ./web3-client
```

##  Architecture

### Keeper Bot
The keeper bot monitors the vault state and triggers rebalancing when conditions are met:
1. Fetches current portfolio state
2. Queries ML engine for predictions
3. Runs optimization solver
4. Executes rebalance transaction

### Web3 Client
Handles all blockchain interactions:
- RPC connection management
- Transaction signing and submission
- Gas estimation and optimization
- Contract ABI encoding/decoding

### Data Aggregator
Collects data from multiple sources:
- On-chain data (vault state, oracle prices)
- Off-chain APIs (protocol metrics, market data)
- Historical data for ML training

### Optimization Solver
Implements the portfolio optimization algorithm:
- Quadratic programming solver
- Risk constraints
- Allocation limits
- Transaction cost minimization

### API Service
REST API for monitoring and management:
- Portfolio metrics
- Strategy performance
- Rebalancing history
- System health

##  Security

- Private keys stored in environment variables
- Secure RPC connection (HTTPS/WSS)
- Rate limiting on API endpoints
- Input validation and sanitization

##  License

MIT License
