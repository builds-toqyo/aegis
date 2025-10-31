# Contributing to Aegis Yield

Thank you for your interest in contributing to Aegis Yield! This document provides guidelines for contributing to the project.

## 🏗️ Project Structure

Aegis Yield is a monorepo with three main components:

- **`contracts/`** - Solidity smart contracts (Foundry)
- **`backend/`** - Go backend services (Keeper bot, API)
- **`ml-engine/`** - Python ML models and API

## 🚀 Getting Started

1. **Fork the repository**
2. **Clone your fork**
   ```bash
   git clone https://github.com/your-username/aegis-yield.git
   cd aegis-yield
   ```
3. **Run setup**
   ```bash
   ./scripts/setup.sh
   ```
4. **Create a branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

## 📝 Development Workflow

### Smart Contracts

```bash
cd contracts

# Make changes to contracts
# Add tests in test/

# Run tests
forge test

# Check coverage
forge coverage

# Format code
forge fmt
```

### Backend (Go)

```bash
cd backend

# Make changes
# Add tests

# Run tests
go test ./...

# Format code
go fmt ./...

# Lint
golangci-lint run
```

### ML Engine (Python)

```bash
cd ml-engine
source venv/bin/activate

# Make changes
# Add tests in tests/

# Run tests
pytest

# Format code
black .
isort .

# Type check
mypy src/
```

## ✅ Code Quality Standards

### Solidity
- Follow [Solidity Style Guide](https://docs.soliditylang.org/en/latest/style-guide.html)
- Use NatSpec comments for all public functions
- Maintain >90% test coverage
- No compiler warnings

### Go
- Follow [Effective Go](https://go.dev/doc/effective_go)
- Use meaningful variable names
- Add comments for exported functions
- Maintain >80% test coverage

### Python
- Follow [PEP 8](https://pep8.org/)
- Use type hints
- Add docstrings for all functions
- Maintain >75% test coverage

## 🧪 Testing

All contributions must include tests:

```bash
# Run all tests
./scripts/test-all.sh

# Run specific component tests
cd contracts && forge test
cd backend && go test ./...
cd ml-engine && pytest
```

## 📤 Submitting Changes

1. **Commit your changes**
   ```bash
   git add .
   git commit -m "feat: add new feature"
   ```

2. **Use conventional commits**
   - `feat:` - New feature
   - `fix:` - Bug fix
   - `docs:` - Documentation
   - `test:` - Tests
   - `refactor:` - Code refactoring
   - `chore:` - Maintenance

3. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```

4. **Create a Pull Request**
   - Provide a clear description
   - Reference any related issues
   - Ensure CI passes

## 🔒 Security

- Never commit private keys or secrets
- Report security vulnerabilities privately
- Follow secure coding practices

## 📋 Pull Request Checklist

- [ ] Code follows style guidelines
- [ ] Tests added and passing
- [ ] Documentation updated
- [ ] No merge conflicts
- [ ] CI/CD passing
- [ ] Reviewed by maintainer

## 🤝 Code Review Process

1. Maintainer reviews PR
2. Feedback provided
3. Changes requested (if needed)
4. Approval and merge

## 📞 Getting Help

- Open an issue for bugs
- Start a discussion for questions
- Join our Discord community

## 📜 License

By contributing, you agree that your contributions will be licensed under the MIT License.

Thank you for contributing to Aegis Yield! 🚀
