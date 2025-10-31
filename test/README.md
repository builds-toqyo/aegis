# Aegis Yield End-to-End Tests

Comprehensive end-to-end testing suite for the Aegis Yield ecosystem.

##  Directory Structure

```
test/
 integration/        # Integration tests
    vault_test.py
    controller_test.py
    strategies_test.py
 e2e/               # End-to-end scenarios
    deposit_withdraw_test.py
    rebalance_test.py
    emergency_test.py
 fixtures/          # Test fixtures and data
    contracts.json
    test_data.json
 utils/             # Test utilities
     helpers.py
     assertions.py
```

##  Test Categories

### Unit Tests
- **Contracts**: `contracts/test/` (Foundry tests)
- **Backend**: `backend/*_test.go` (Go tests)
- **ML Engine**: `ml-engine/tests/` (Pytest)

### Integration Tests
Test interactions between components:
- Vault  Controller
- Controller  Strategies
- Backend  Blockchain
- Backend  ML Engine

### End-to-End Tests
Full user flows:
- Deposit  Rebalance  Withdraw
- Emergency scenarios
- Multi-strategy operations

##  Running Tests

### All Tests
```bash
# Run everything
./scripts/test-all.sh
```

### By Component
```bash
# Solidity tests
cd contracts && forge test

# Go tests
cd backend && go test ./...

# Python tests
cd ml-engine && pytest

# Integration tests
cd test && pytest integration/

# E2E tests
cd test && pytest e2e/
```

### With Coverage
```bash
# Solidity coverage
cd contracts && forge coverage

# Go coverage
cd backend && go test -cover ./...

# Python coverage
cd ml-engine && pytest --cov=src
```

##  Test Requirements

- Local Anvil node for contract tests
- Test RPC endpoint for integration tests
- Mock ML service for backend tests

##  Configuration

Create `test/.env.test`:
```bash
TEST_RPC_URL=http://localhost:8545
TEST_PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
ML_API_URL=http://localhost:5000
```

##  Writing Tests

### Solidity (Foundry)
```solidity
function testDeposit() public {
    uint256 amount = 1000e6;
    asset.mint(user, amount);
    
    vm.startPrank(user);
    asset.approve(address(vault), amount);
    vault.deposit(amount, user);
    vm.stopPrank();
    
    assertEq(vault.balanceOf(user), amount);
}
```

### Go
```go
func TestRebalance(t *testing.T) {
    // Setup
    solver := NewOptimizationSolver(0.5)
    
    // Execute
    results, err := solver.Optimize(strategies, totalAssets)
    
    // Assert
    assert.NoError(t, err)
    assert.Len(t, results, 3)
}
```

### Python
```python
def test_prediction():
    model = LSTMPredictor(input_size=10)
    x = torch.randn(1, 7, 10)
    
    output = model(x)
    
    assert output.shape == (1, 2)
```

##  Coverage Goals

- Contracts: >90%
- Backend: >80%
- ML Engine: >75%
- Integration: >70%

##  CI/CD Integration

Tests run automatically on:
- Pull requests
- Commits to main
- Pre-deployment

See `.github/workflows/test.yml` for CI configuration.
