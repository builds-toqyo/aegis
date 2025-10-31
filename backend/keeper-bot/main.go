package main

import (
	"context"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/joho/godotenv"
	"github.com/sirupsen/logrus"
	
	"github.com/aegis-yield/backend/web3-client"
)

var logger = logrus.New()

func main() {
	// Load environment variables
	if err := godotenv.Load(); err != nil {
		logger.Warn("No .env file found")
	}

	// Configure logger
	logger.SetFormatter(&logrus.JSONFormatter{})
	logger.SetLevel(logrus.InfoLevel)

	logger.Info("Starting Aegis Yield Keeper Bot...")

	// Load configuration from environment
	rpcURL := os.Getenv("BASE_RPC_URL")
	if rpcURL == "" {
		rpcURL = "https://mainnet.base.org"
	}

	artifactsPath := os.Getenv("DEPLOYMENT_ARTIFACTS_PATH")
	if artifactsPath == "" {
		artifactsPath = "./deployments/base-deployment.json"
	}

	privateKeyHex := os.Getenv("KEEPER_PRIVATE_KEY")
	if privateKeyHex == "" {
		logger.Fatal("KEEPER_PRIVATE_KEY environment variable is required")
	}

	mlAPIURL := os.Getenv("ML_API_URL")
	if mlAPIURL == "" {
		mlAPIURL = "http://localhost:5000"
	}

	// Initialize contract manager
	contractManager, err := web3client.NewContractManager(rpcURL, artifactsPath, privateKeyHex, logger)
	if err != nil {
		logger.WithError(err).Fatal("Failed to initialize contract manager")
	}
	defer contractManager.Close()

	// Initialize rebalancer
	rebalancer := NewRebalancer(contractManager, mlAPIURL, logger)

	// Create context with cancellation
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// Setup graceful shutdown
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)

	go func() {
		<-sigChan
		logger.Info("Shutdown signal received, stopping keeper bot...")
		cancel()
	}()

	// Start the keeper bot
	if err := runKeeper(ctx, rebalancer); err != nil {
		logger.WithError(err).Fatal("Keeper bot failed")
	}

	logger.Info("Keeper bot stopped gracefully")
}

func runKeeper(ctx context.Context, rebalancer *Rebalancer) error {
	// Rebalancing interval from environment or default to 1 hour
	intervalStr := os.Getenv("REBALANCE_INTERVAL")
	rebalanceInterval := time.Hour
	if intervalStr != "" {
		if duration, err := time.ParseDuration(intervalStr); err == nil {
			rebalanceInterval = duration
		}
	}

	ticker := time.NewTicker(rebalanceInterval)
	defer ticker.Stop()

	logger.WithField("interval", rebalanceInterval).Info("Keeper bot started")

	// Execute rebalance immediately on startup
	if err := rebalancer.ExecuteRebalance(ctx); err != nil {
		logger.WithError(err).Error("Initial rebalancing failed")
	}

	for {
		select {
		case <-ctx.Done():
			return nil
		case <-ticker.C:
			if err := rebalancer.ExecuteRebalance(ctx); err != nil {
				logger.WithError(err).Error("Rebalancing failed")
			}
		}
	}
}
