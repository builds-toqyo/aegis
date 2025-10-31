package web3client

import (
	"context"
	"crypto/ecdsa"
	"encoding/json"
	"fmt"
	"math/big"
	"os"

	"github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"
	"github.com/sirupsen/logrus"
)

// DeploymentArtifacts contains all deployed contract addresses and configuration
type DeploymentArtifacts struct {
	Network                   string         `json:"network"`
	ChainID                   uint64         `json:"chainId"`
	VaultImplementation       common.Address `json:"vaultImplementation"`
	VaultProxy                common.Address `json:"vaultProxy"`
	ControllerImplementation  common.Address `json:"controllerImplementation"`
	ControllerProxy           common.Address `json:"controllerProxy"`
	AaveStrategy              common.Address `json:"aaveStrategy"`
	Asset                     common.Address `json:"asset"`
	Deployer                  common.Address `json:"deployer"`
	KeeperEOA                 common.Address `json:"keeperEOA"`
	AdminMultisig             common.Address `json:"adminMultisig"`
	DefaultAdminRole          string         `json:"DEFAULT_ADMIN_ROLE"`
	KeeperRole                string         `json:"KEEPER_ROLE"`
	StrategistRole            string         `json:"STRATEGIST_ROLE"`
}

// ContractManager manages all contract interactions
type ContractManager struct {
	client     *ethclient.Client
	artifacts  *DeploymentArtifacts
	privateKey *ecdsa.PrivateKey
	auth       *bind.TransactOpts
	logger     *logrus.Logger
}

// NewContractManager creates a new contract manager instance
func NewContractManager(rpcURL, artifactsPath, privateKeyHex string, logger *logrus.Logger) (*ContractManager, error) {
	// Connect to Base RPC
	client, err := ethclient.Dial(rpcURL)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to Base RPC: %w", err)
	}

	// Load deployment artifacts
	artifacts, err := loadDeploymentArtifacts(artifactsPath)
	if err != nil {
		return nil, fmt.Errorf("failed to load deployment artifacts: %w", err)
	}

	// Load private key
	privateKey, err := crypto.HexToECDSA(privateKeyHex)
	if err != nil {
		return nil, fmt.Errorf("failed to load private key: %w", err)
	}

	// Create transactor with Base chain ID (8453)
	chainID := big.NewInt(int64(artifacts.ChainID))
	auth, err := bind.NewKeyedTransactorWithChainID(privateKey, chainID)
	if err != nil {
		return nil, fmt.Errorf("failed to create transactor: %w", err)
	}

	logger.WithFields(logrus.Fields{
		"network":    artifacts.Network,
		"chainId":    artifacts.ChainID,
		"controller": artifacts.ControllerProxy.Hex(),
		"vault":      artifacts.VaultProxy.Hex(),
	}).Info("Contract manager initialized")

	return &ContractManager{
		client:     client,
		artifacts:  artifacts,
		privateKey: privateKey,
		auth:       auth,
		logger:     logger,
	}, nil
}

// loadDeploymentArtifacts loads the deployment JSON file
func loadDeploymentArtifacts(path string) (*DeploymentArtifacts, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("failed to read artifacts file: %w", err)
	}

	var artifacts DeploymentArtifacts
	if err := json.Unmarshal(data, &artifacts); err != nil {
		return nil, fmt.Errorf("failed to parse artifacts JSON: %w", err)
	}

	return &artifacts, nil
}

// GetClient returns the eth client
func (cm *ContractManager) GetClient() *ethclient.Client {
	return cm.client
}

// GetControllerAddress returns the controller proxy address
func (cm *ContractManager) GetControllerAddress() common.Address {
	return cm.artifacts.ControllerProxy
}

// GetVaultAddress returns the vault proxy address
func (cm *ContractManager) GetVaultAddress() common.Address {
	return cm.artifacts.VaultProxy
}

// GetAuth returns the transaction auth with updated gas settings
func (cm *ContractManager) GetAuth(ctx context.Context) (*bind.TransactOpts, error) {
	// Get latest nonce
	nonce, err := cm.client.PendingNonceAt(ctx, cm.auth.From)
	if err != nil {
		return nil, fmt.Errorf("failed to get nonce: %w", err)
	}

	// Get suggested gas price
	gasPrice, err := cm.client.SuggestGasPrice(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to get gas price: %w", err)
	}

	// Create new auth with updated values
	auth := *cm.auth
	auth.Nonce = big.NewInt(int64(nonce))
	auth.GasPrice = gasPrice
	auth.Context = ctx

	return &auth, nil
}

// EstimateGas estimates gas for a transaction
func (cm *ContractManager) EstimateGas(ctx context.Context, to common.Address, data []byte) (uint64, error) {
	msg := ethereum.CallMsg{
		From: cm.auth.From,
		To:   &to,
		Data: data,
	}

	gasLimit, err := cm.client.EstimateGas(ctx, msg)
	if err != nil {
		return 0, fmt.Errorf("failed to estimate gas: %w", err)
	}

	// Add 20% buffer
	return gasLimit * 120 / 100, nil
}

// WaitForTransaction waits for a transaction to be mined
func (cm *ContractManager) WaitForTransaction(ctx context.Context, txHash common.Hash) error {
	cm.logger.WithField("txHash", txHash.Hex()).Info("Waiting for transaction confirmation...")

	receipt, err := bind.WaitMined(ctx, cm.client, &types.Transaction{})
	if err != nil {
		return fmt.Errorf("failed to wait for transaction: %w", err)
	}

	if receipt.Status == 0 {
		return fmt.Errorf("transaction failed: %s", txHash.Hex())
	}

	cm.logger.WithFields(logrus.Fields{
		"txHash":      txHash.Hex(),
		"blockNumber": receipt.BlockNumber,
		"gasUsed":     receipt.GasUsed,
	}).Info("Transaction confirmed")

	return nil
}

// Close closes the client connection
func (cm *ContractManager) Close() {
	cm.client.Close()
}
