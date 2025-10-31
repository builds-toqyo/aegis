// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title AegisRiskMath
 * @notice Mathematical utilities for risk calculations and portfolio optimization
 * @dev Used by strategies and controller for risk-adjusted returns
 */
library AegisRiskMath {
    uint256 private constant BASIS_POINTS = 10_000;
    uint256 private constant PRECISION = 1e18;

    /**
     * @notice Calculates the Sharpe ratio (risk-adjusted return)
     * @param expectedReturns The expected returns (in basis points)
     * @param volatility The volatility (in basis points)
     * @param riskFreeRate The risk-free rate (in basis points)
     * @return sharpeRatio The Sharpe ratio (scaled by PRECISION)
     */
    function calculateSharpeRatio(
        uint256 expectedReturns,
        uint256 volatility,
        uint256 riskFreeRate
    ) internal pure returns (uint256 sharpeRatio) {
        require(volatility > 0, "AegisRiskMath: zero volatility");
        
        if (expectedReturns <= riskFreeRate) {
            return 0;
        }
        
        uint256 excessReturn = expectedReturns - riskFreeRate;
        sharpeRatio = (excessReturn * PRECISION) / volatility;
    }

    /**
     * @notice Calculates portfolio variance given allocations and covariances
     * @param allocations Array of allocation percentages (in basis points)
     * @param variances Array of individual asset variances
     * @return portfolioVariance The portfolio variance
     */
    function calculatePortfolioVariance(
        uint256[] memory allocations,
        uint256[] memory variances
    ) internal pure returns (uint256 portfolioVariance) {
        require(allocations.length == variances.length, "AegisRiskMath: length mismatch");
        
        for (uint256 i = 0; i < allocations.length; i++) {
            uint256 weightSquared = (allocations[i] * allocations[i]) / BASIS_POINTS;
            portfolioVariance += (weightSquared * variances[i]) / BASIS_POINTS;
        }
    }

    /**
     * @notice Calculates the maximum drawdown risk
     * @param currentValue The current portfolio value
     * @param peakValue The peak portfolio value
     * @return drawdown The drawdown percentage (in basis points)
     */
    function calculateDrawdown(
        uint256 currentValue,
        uint256 peakValue
    ) internal pure returns (uint256 drawdown) {
        require(peakValue > 0, "AegisRiskMath: zero peak value");
        
        if (currentValue >= peakValue) {
            return 0;
        }
        
        uint256 loss = peakValue - currentValue;
        drawdown = (loss * BASIS_POINTS) / peakValue;
    }

    /**
     * @notice Normalizes allocations to sum to 100%
     * @param allocations Array of allocation amounts
     * @return normalized Array of normalized allocations (in basis points)
     */
    function normalizeAllocations(
        uint256[] memory allocations
    ) internal pure returns (uint256[] memory normalized) {
        uint256 total = 0;
        normalized = new uint256[](allocations.length);
        
        for (uint256 i = 0; i < allocations.length; i++) {
            total += allocations[i];
        }
        
        require(total > 0, "AegisRiskMath: zero total allocation");
        
        for (uint256 i = 0; i < allocations.length; i++) {
            normalized[i] = (allocations[i] * BASIS_POINTS) / total;
        }
    }

    /**
     * @notice Calculates the Value at Risk (VaR) using historical method
     * @param portfolioValue The current portfolio value
     * @param volatility The portfolio volatility (in basis points)
     * @param confidenceLevel The confidence level (in basis points, e.g., 9500 for 95%)
     * @return var The Value at Risk
     */
    function calculateVaR(
        uint256 portfolioValue,
        uint256 volatility,
        uint256 confidenceLevel
    ) internal pure returns (uint256 var) {
        // Simplified VaR calculation using normal distribution approximation
        // For 95% confidence: z-score ≈ 1.645
        // For 99% confidence: z-score ≈ 2.326
        
        uint256 zScore;
        if (confidenceLevel >= 9900) {
            zScore = 2326; // 99% confidence
        } else if (confidenceLevel >= 9500) {
            zScore = 1645; // 95% confidence
        } else {
            zScore = 1282; // 90% confidence
        }
        
        var = (portfolioValue * volatility * zScore) / (BASIS_POINTS * 1000);
    }

    /**
     * @notice Checks if allocation respects risk limits
     * @param allocation The proposed allocation (in basis points)
     * @param maxAllocation The maximum allowed allocation (in basis points)
     * @return valid Whether the allocation is valid
     */
    function isAllocationValid(
        uint256 allocation,
        uint256 maxAllocation
    ) internal pure returns (bool valid) {
        return allocation <= maxAllocation && allocation <= BASIS_POINTS;
    }

    /**
     * @notice Calculates the weighted average APY
     * @param apys Array of APYs (in basis points)
     * @param allocations Array of allocations (in basis points)
     * @return weightedAPY The weighted average APY
     */
    function calculateWeightedAPY(
        uint256[] memory apys,
        uint256[] memory allocations
    ) internal pure returns (uint256 weightedAPY) {
        require(apys.length == allocations.length, "AegisRiskMath: length mismatch");
        
        for (uint256 i = 0; i < apys.length; i++) {
            weightedAPY += (apys[i] * allocations[i]) / BASIS_POINTS;
        }
    }
}
