package web3client

import (
	"context"
	"crypto/ecdsa"
	"math/big"

	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"
)

// BaseConnector handles connections to Base L2
type BaseConnector struct {
	client     *ethclient.Client
	chainID    *big.Int
	privateKey *ecdsa.PrivateKey
	address    common.Address
}

// NewBaseConnector creates a new Base connector
func NewBaseConnector(rpcURL string, privateKeyHex string) (*BaseConnector, error) {
	// Connect to Base RPC
	client, err := ethclient.Dial(rpcURL)
	if err != nil {
		return nil, err
	}

	// Get chain ID
	chainID, err := client.ChainID(context.Background())
	if err != nil {
		return nil, err
	}

	// Parse private key
	privateKey, err := crypto.HexToECDSA(privateKeyHex)
	if err != nil {
		return nil, err
	}

	// Derive address
	publicKey := privateKey.Public()
	publicKeyECDSA, ok := publicKey.(*ecdsa.PublicKey)
	if !ok {
		return nil, err
	}
	address := crypto.PubkeyToAddress(*publicKeyECDSA)

	return &BaseConnector{
		client:     client,
		chainID:    chainID,
		privateKey: privateKey,
		address:    address,
	}, nil
}

// GetTransactor returns a transactor for signing transactions
func (bc *BaseConnector) GetTransactor(ctx context.Context) (*bind.TransactOpts, error) {
	nonce, err := bc.client.PendingNonceAt(ctx, bc.address)
	if err != nil {
		return nil, err
	}

	gasPrice, err := bc.client.SuggestGasPrice(ctx)
	if err != nil {
		return nil, err
	}

	auth, err := bind.NewKeyedTransactorWithChainID(bc.privateKey, bc.chainID)
	if err != nil {
		return nil, err
	}

	auth.Nonce = big.NewInt(int64(nonce))
	auth.Value = big.NewInt(0)
	auth.GasLimit = uint64(300000) // Default gas limit
	auth.GasPrice = gasPrice

	return auth, nil
}

// SendTransaction sends a signed transaction
func (bc *BaseConnector) SendTransaction(ctx context.Context, tx *types.Transaction) error {
	return bc.client.SendTransaction(ctx, tx)
}

// WaitForTransaction waits for a transaction to be mined
func (bc *BaseConnector) WaitForTransaction(ctx context.Context, txHash common.Hash) (*types.Receipt, error) {
	return bind.WaitMined(ctx, bc.client, &types.Transaction{})
}

// GetBalance returns the ETH balance of an address
func (bc *BaseConnector) GetBalance(ctx context.Context, address common.Address) (*big.Int, error) {
	return bc.client.BalanceAt(ctx, address, nil)
}

// Close closes the client connection
func (bc *BaseConnector) Close() {
	bc.client.Close()
}
