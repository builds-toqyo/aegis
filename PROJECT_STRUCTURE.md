# Aegis Yield - Complete Project Structure

## 📋 Overview

Aegis Yield is a comprehensive DeFi yield optimization platform built as a monorepo containing three distinct technology stacks working in harmony:

1. **Solidity Smart Contracts** (Base L2)
2. **Go Backend Services** (Keeper Bot & API)
3. **Python ML Engine** (LSTM Predictions)

---

## 🏗️ Complete Directory Tree

```
aegis/
├── README.md                      # Main project documentation
├── LICENSE                        # MIT License
├── CONTRIBUTING.md               # Contribution guidelines
├── .gitignore                    # Git ignore rules
├── .env.example                  # Environment template
│
├── contracts/                    # 📜 Solidity Smart Contracts
│   ├── foundry.toml             # Foundry configuration
│   ├── README.md
│   ├── src/
│   │   ├── vault/
│   │   │   ├── AegisVault.sol           # ERC-4626 vault
│   │   │   └── AegisController.sol      # Strategy controller
│   │   ├── strategies/
│   │   │   ├── BaseStrategy.sol         # Abstract base
│   │   │   ├── StrategyAaveBase.sol     # Aave lending
│   │   │   ├── StrategyLidoL1.sol       # Lido staking (TODO)
│   │   │   └── StrategyDeltaMax.sol     # Delta-neutral (TODO)
│   │   ├── interfaces/
│   │   │   ├── IAegisStrategy.sol
│   │   │   ├── IAegisController.sol
│   │   │   ├── IBridge.sol
│   │   │   └── IRiskOracle.sol
│   │   ├── libs/
│   │   │   └── AegisRiskMath.sol        # Risk calculations
│   │   └── mocks/
│   │       ├── MockERC20.sol
│   │       ├── MockChainlinkFeed.sol
│   │       └── MockBridge.sol
│   ├── script/
│   │   └── Deploy.s.sol                 # Deployment script
│   └── test/
│       └── AegisVault.t.sol             # Foundry tests
│
├── backend/                      # 🖥️ Go Backend Services
│   ├── go.mod
│   ├── README.md
│   ├── keeper-bot/
│   │   └── main.go                      # Keeper bot entry point
│   ├── web3-client/
│   │   ├── base_connector.go            # Base L2 connector
│   │   └── contracts.go                 # Contract bindings (TODO)
│   ├── data-aggregator/
│   │   ├── aggregator.go                # Data collection
│   │   └── sources.go                   # Data sources (TODO)
│   ├── optimization-solver/
│   │   ├── solver.go                    # Portfolio optimizer
│   │   └── constraints.go               # Constraints (TODO)
│   ├── api-service/
│   │   ├── main.go                      # API entry point
│   │   ├── handlers.go                  # Route handlers (TODO)
│   │   └── middleware.go                # Middleware (TODO)
│   └── pkg/
│       ├── config/
│       │   └── config.go                # Configuration
│       ├── logger/                      # Logging (TODO)
│       └── utils/                       # Utilities (TODO)
│
├── ml-engine/                    # 🧠 Python ML Engine
│   ├── requirements.txt
│   ├── README.md
│   ├── data/
│   │   ├── raw/                         # Raw historical data
│   │   └── processed/                   # Processed data
│   ├── models/
│   │   ├── lstm_v1.pth                  # Trained model (TODO)
│   │   └── scaler.joblib                # Feature scaler (TODO)
│   ├── scripts/
│   │   ├── train.py                     # Training script
│   │   ├── evaluate.py                  # Evaluation (TODO)
│   │   └── predict.py                   # Prediction (TODO)
│   ├── api/
│   │   ├── ml_service.py                # Flask/FastAPI service
│   │   └── schemas.py                   # API schemas (TODO)
│   └── src/
│       ├── models/
│       │   └── lstm_model.py            # LSTM architecture
│       ├── preprocessing/
│       │   └── data_loader.py           # Data loading
│       └── utils/
│           └── metrics.py               # Evaluation metrics
│
├── scripts/                      # 🔧 Automation Scripts
│   ├── README.md
│   ├── setup.sh                         # Initial setup
│   ├── deploy-contracts.sh              # Deploy to Base
│   ├── start-keeper.sh                  # Start keeper bot
│   ├── start-ml-service.sh              # Start ML API
│   └── start-api.sh                     # Start REST API (TODO)
│
└── test/                         # 🧪 End-to-End Tests
    ├── README.md
    ├── integration/
    │   ├── vault_test.py                # Vault integration tests
    │   ├── controller_test.py           # Controller tests (TODO)
    │   └── strategies_test.py           # Strategy tests (TODO)
    ├── e2e/
    │   ├── deposit_withdraw_test.py     # E2E flows (TODO)
    │   ├── rebalance_test.py            # Rebalancing (TODO)
    │   └── emergency_test.py            # Emergency scenarios (TODO)
    ├── fixtures/
    │   ├── contracts.json               # Contract fixtures (TODO)
    │   └── test_data.json               # Test data (TODO)
    └── utils/
        ├── helpers.py                   # Test helpers (TODO)
        └── assertions.py                # Custom assertions (TODO)
```

---

## 🎯 Key Components

### Smart Contracts (Solidity)

**AegisVault.sol**
- ERC-4626 compliant tokenized vault
- UUPS upgradeable pattern
- Performance and management fees
- Pause mechanism for emergencies

**AegisController.sol**
- Central "brain" of the system
- Manages strategy allocation
- Executes rebalancing based on keeper signals
- Role-based access control (ADMIN, KEEPER, STRATEGIST)

**Strategies**
- **BaseStrategy**: Abstract base with common functionality
- **StrategyAaveBase**: Aave v3 lending on Base
- **StrategyLidoL1**: L1 Lido staking via bridge (TODO)
- **StrategyDeltaMax**: Delta-neutral farming (TODO)

### Backend (Go)

**Keeper Bot**
- Monitors portfolio state
- Queries ML engine for predictions
- Executes rebalancing transactions
- Configurable intervals and gas optimization

**Web3 Client**
- Base L2 RPC connection
- Transaction signing and submission
- Gas estimation
- Contract interaction

**Optimization Solver**
- Portfolio optimization algorithm
- Risk-adjusted allocation
- Constraint handling
- Sharpe ratio maximization

**API Service**
- REST API for monitoring
- Portfolio metrics
- Strategy performance
- Rebalancing history

### ML Engine (Python)

**LSTM Model**
- Time series forecasting
- Predicts APY and volatility
- 7-day prediction window
- Attention mechanism variant available

**Data Pipeline**
- Historical data collection
- Feature engineering
- Normalization and scaling
- Train/test splitting

**API Service**
- Flask/FastAPI endpoints
- Prediction serving
- Model retraining triggers
- Health monitoring

---

## 🚀 Getting Started

### Prerequisites

```bash
# Required
- Foundry (https://getfoundry.sh)
- Go 1.21+ (https://go.dev)
- Python 3.10+ (https://python.org)

# Optional
- Node.js 18+ (for tooling)
- Docker (for containerization)
```

### Quick Setup

```bash
# 1. Clone repository
git clone <repo-url>
cd aegis

# 2. Run setup script
chmod +x scripts/*.sh
./scripts/setup.sh

# 3. Configure environment
cp .env.example .env
# Edit .env with your values

# 4. Deploy contracts (testnet)
./scripts/deploy-contracts.sh base-testnet

# 5. Start services
./scripts/start-keeper.sh &
./scripts/start-ml-service.sh &
```

---

## 📊 Architecture Flow

```
┌─────────────┐
│   Users     │
└──────┬──────┘
       │ Deposit/Withdraw
       ▼
┌─────────────────────┐
│   AegisVault.sol    │ (ERC-4626)
│   (Base L2)         │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│ AegisController.sol │ (Strategy Manager)
└──────┬──────────────┘
       │
       ├──────────┬──────────┬──────────┐
       ▼          ▼          ▼          ▼
   ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐
   │ Aave │  │ Lido │  │Delta │  │ ... │
   └──────┘  └──────┘  └──────┘  └──────┘

       ▲
       │ Rebalance Signal
       │
┌──────────────────┐
│   Keeper Bot     │ (Go)
│   - Monitors     │
│   - Optimizes    │
└────┬─────────────┘
     │
     │ Get Predictions
     ▼
┌──────────────────┐
│   ML Engine      │ (Python)
│   - LSTM Model   │
│   - Predictions  │
└──────────────────┘
```

---

## 🔐 Security Features

- **UUPS Upgradeable**: Secure upgrade pattern
- **Access Control**: Role-based permissions
- **Reentrancy Guards**: Protection against attacks
- **Pause Mechanism**: Emergency stop functionality
- **Fee Limits**: Maximum fee caps
- **Allocation Limits**: Per-strategy caps

---

## 📝 Next Steps

### Immediate TODOs

1. **Install Dependencies**
   ```bash
   cd contracts && forge install
   cd ../backend && go mod download
   cd ../ml-engine && pip install -r requirements.txt
   ```

2. **Complete Strategy Implementations**
   - StrategyLidoL1.sol
   - StrategyDeltaMax.sol

3. **Train ML Model**
   ```bash
   cd ml-engine
   python scripts/train.py
   ```

4. **Deploy to Testnet**
   ```bash
   ./scripts/deploy-contracts.sh base-testnet
   ```

5. **Run Integration Tests**
   ```bash
   cd test && pytest integration/
   ```

### Future Enhancements

- [ ] Multi-chain support
- [ ] Advanced ML models (Transformers)
- [ ] Frontend dashboard
- [ ] Governance token
- [ ] Additional strategies
- [ ] Risk oracle integration
- [ ] Automated testing CI/CD

---

## 📚 Documentation

- **Contracts**: See `contracts/README.md`
- **Backend**: See `backend/README.md`
- **ML Engine**: See `ml-engine/README.md`
- **Scripts**: See `scripts/README.md`
- **Tests**: See `test/README.md`

---

## 🤝 Contributing

See `CONTRIBUTING.md` for development guidelines.

---

## 📄 License

MIT License - See `LICENSE` file for details.

---

**Built with ❤️ for DeFi yield optimization**
