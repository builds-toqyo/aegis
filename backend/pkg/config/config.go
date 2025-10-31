package config

import (
	"os"
	"strconv"
)

// Config holds application configuration
type Config struct {
	// Blockchain
	BaseRPCURL      string
	BaseChainID     int64
	KeeperPrivateKey string
	
	// Contracts
	VaultAddress      string
	ControllerAddress string
	
	// Keeper
	RebalanceInterval int
	GasPriceMultiplier float64
	
	// ML Engine
	MLAPIUrl string
	
	// API
	APIPort string
	APIHost string
}

// LoadConfig loads configuration from environment variables
func LoadConfig() *Config {
	rebalanceInterval, _ := strconv.Atoi(getEnv("REBALANCE_INTERVAL_SECONDS", "3600"))
	gasPriceMultiplier, _ := strconv.ParseFloat(getEnv("GAS_PRICE_MULTIPLIER", "1.1"), 64)
	
	return &Config{
		BaseRPCURL:         getEnv("BASE_RPC_URL", "https://mainnet.base.org"),
		BaseChainID:        8453,
		KeeperPrivateKey:   getEnv("KEEPER_PRIVATE_KEY", ""),
		VaultAddress:       getEnv("AEGIS_VAULT_ADDRESS", ""),
		ControllerAddress:  getEnv("AEGIS_CONTROLLER_ADDRESS", ""),
		RebalanceInterval:  rebalanceInterval,
		GasPriceMultiplier: gasPriceMultiplier,
		MLAPIUrl:           getEnv("ML_API_URL", "http://localhost:5000"),
		APIPort:            getEnv("API_PORT", "8080"),
		APIHost:            getEnv("API_HOST", "0.0.0.0"),
	}
}

func getEnv(key, defaultValue string) string {
	value := os.Getenv(key)
	if value == "" {
		return defaultValue
	}
	return value
}
