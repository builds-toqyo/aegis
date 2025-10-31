package solver

import (
	"errors"
	"math"
)

// OptimizationSolver implements portfolio optimization
type OptimizationSolver struct {
	// Solver parameters
	riskTolerance float64
	minAllocation float64
	maxAllocation float64
}

// StrategyInput represents input data for a strategy
type StrategyInput struct {
	Name           string
	CurrentAlloc   float64
	ExpectedReturn float64
	Volatility     float64
	RiskScore      float64
	MaxAllocation  float64
}

// AllocationResult represents the optimal allocation
type AllocationResult struct {
	Strategy   string
	Allocation float64
	Weight     float64
}

// NewOptimizationSolver creates a new solver
func NewOptimizationSolver(riskTolerance float64) *OptimizationSolver {
	return &OptimizationSolver{
		riskTolerance: riskTolerance,
		minAllocation: 0.05, // 5% minimum
		maxAllocation: 0.50, // 50% maximum
	}
}

// Optimize calculates the optimal portfolio allocation
func (os *OptimizationSolver) Optimize(
	strategies []StrategyInput,
	totalAssets float64,
) ([]AllocationResult, error) {
	if len(strategies) == 0 {
		return nil, errors.New("no strategies provided")
	}

	// Calculate risk-adjusted scores (Sharpe ratio approximation)
	scores := make([]float64, len(strategies))
	totalScore := 0.0

	for i, strategy := range strategies {
		// Risk-adjusted return = (Expected Return - Risk Free Rate) / Volatility
		// Simplified: just use return / (volatility * risk_score)
		if strategy.Volatility > 0 && strategy.RiskScore > 0 {
			scores[i] = strategy.ExpectedReturn / (strategy.Volatility * strategy.RiskScore / 100.0)
		} else {
			scores[i] = strategy.ExpectedReturn
		}
		totalScore += scores[i]
	}

	// Normalize scores to get weights
	results := make([]AllocationResult, len(strategies))
	
	for i, strategy := range strategies {
		weight := scores[i] / totalScore
		
		// Apply constraints
		weight = math.Max(weight, os.minAllocation)
		weight = math.Min(weight, os.maxAllocation)
		weight = math.Min(weight, strategy.MaxAllocation)

		allocation := weight * totalAssets

		results[i] = AllocationResult{
			Strategy:   strategy.Name,
			Allocation: allocation,
			Weight:     weight,
		}
	}

	// Normalize weights to sum to 1.0
	results = normalizeWeights(results, totalAssets)

	return results, nil
}

// normalizeWeights ensures weights sum to 1.0
func normalizeWeights(results []AllocationResult, totalAssets float64) []AllocationResult {
	totalWeight := 0.0
	for _, r := range results {
		totalWeight += r.Weight
	}

	if totalWeight == 0 {
		return results
	}

	for i := range results {
		results[i].Weight = results[i].Weight / totalWeight
		results[i].Allocation = results[i].Weight * totalAssets
	}

	return results
}
