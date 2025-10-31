package main

import (
	"context"
	// "log"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/joho/godotenv"
	"github.com/sirupsen/logrus"
)

var logger = logrus.New()

func main() {
	// Load environment variables
	if err := godotenv.Load(); err != nil {
		logger.Warn("No .env file found")
	}

	// Initialize logger
	logger.SetFormatter(&logrus.JSONFormatter{})
	logger.SetLevel(logrus.InfoLevel)

	logger.Info("Starting Aegis Yield Keeper Bot...")

	// Create context with cancellation
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// Handle graceful shutdown
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)

	// Start keeper bot
	go runKeeper(ctx)

	// Wait for shutdown signal
	<-sigChan
	logger.Info("Shutdown signal received, stopping keeper bot...")
	cancel()

	// Give time for graceful shutdown
	time.Sleep(2 * time.Second)
	logger.Info("Keeper bot stopped")
}

func runKeeper(ctx context.Context) {
	rebalanceInterval := 1 * time.Hour // TODO: Load from config
	ticker := time.NewTicker(rebalanceInterval)
	defer ticker.Stop()

	logger.Info("Keeper bot running, checking for rebalancing opportunities...")

	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			if err := executeRebalance(ctx); err != nil {
				logger.WithError(err).Error("Rebalancing failed")
			}
		}
	}
}

func executeRebalance(_ context.Context) error {
	logger.Info("Checking if rebalancing is needed...")

	// TODO: Implement rebalancing logic
	// 1. Fetch current portfolio state from blockchain
	// 2. Query ML engine for predictions
	// 3. Run optimization solver
	// 4. Execute rebalance transaction if needed

	return nil
}
