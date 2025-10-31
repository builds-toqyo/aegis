# Aegis Yield Smart Contracts

Solidity smart contracts for the Aegis Yield Dynamic Portfolio Vault on Base L2.

## 📁 Directory Structure

```
contracts/
├── src/
│   ├── vault/              # Core vault contracts
│   │   ├── AegisVault.sol
│   │   └── AegisController.sol
│   ├── strategies/         # Yield generation strategies
│   │   ├── StrategyAaveBase.sol
│   │   ├── StrategyLidoL1.sol
│   │   └── StrategyDeltaMax.sol
│   ├── interfaces/         # Contract interfaces
│   │   ├── IAegisStrategy.sol
│   │   ├── IAegisController.sol
│   │   ├── IBridge.sol
│   │   └── IRiskOracle.sol
│   ├── libs/              # Shared libraries
│   │   └── AegisRiskMath.sol
│   └── mocks/             # Testing mocks
│       ├── MockERC20.sol
│       ├── MockChainlinkFeed.sol
│       └── MockBridge.sol
├── script/                # Deployment scripts
├── test/                  # Contract tests
└── foundry.toml          # Foundry configuration
```

## 🚀 Getting Started

### Installation

```bash
# Install Foundry dependencies
forge install OpenZeppelin/openzeppelin-contracts
forge install smartcontractkit/chainlink
forge install foundry-rs/forge-std

# Build contracts
forge build
```

### Testing

```bash
# Run all tests
forge test

# Run with verbosity
forge test -vvv

# Run specific test
forge test --match-test testDeposit

# Generate coverage report
forge coverage
```

### Deployment

```bash
# Deploy to Base testnet
forge script script/Deploy.s.sol --rpc-url base --broadcast --verify

# Deploy to Base mainnet
forge script script/Deploy.s.sol --rpc-url base --broadcast --verify --slow
```

## 🔐 Security Features

- **ERC-4626 Compliance** - Standard tokenized vault interface
- **UUPS Upgradeable** - Secure upgrade pattern via OpenZeppelin
- **Access Control** - Role-based permissions (ADMIN, KEEPER, STRATEGIST)
- **Reentrancy Guards** - Protection against reentrancy attacks
- **Pause Mechanism** - Emergency stop functionality

## 📊 Key Contracts

### AegisVault.sol
ERC-4626 compliant vault that accepts deposits and mints shares. Manages user funds and delegates strategy execution to the Controller.

### AegisController.sol
The "brain" of the system. Receives rebalancing instructions from the keeper bot and orchestrates fund allocation across strategies.

### Strategies
- **StrategyAaveBase** - Lends assets on Aave v3 on Base
- **StrategyLidoL1** - Bridges to L1 for Lido staking (satellite strategy)
- **StrategyDeltaMax** - Delta-neutral yield farming

## 🧪 Testing Strategy

- Unit tests for each contract
- Integration tests for multi-contract interactions
- Fuzz testing for edge cases
- Invariant testing for system properties

## 📝 License

MIT License
