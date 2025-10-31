// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IRiskOracle
 * @notice Interface for risk assessment oracle
 * @dev Provides real-time risk metrics for strategies and protocols
 */
interface IRiskOracle {
    /**
     * @notice Struct representing risk metrics
     */
    struct RiskMetrics {
        uint256 volatility; // Volatility score (0-100)
        uint256 liquidityDepth; // Liquidity depth in USD
        uint256 protocolHealth; // Protocol health score (0-100)
        uint256 timestamp; // Last update timestamp
    }

    /**
     * @notice Returns risk metrics for a given protocol
     * @param protocol The protocol address
     * @return metrics The risk metrics
     */
    function getRiskMetrics(address protocol) external view returns (RiskMetrics memory metrics);

    /**
     * @notice Updates risk metrics for a protocol
     * @param protocol The protocol address
     * @param metrics The new risk metrics
     * @dev Only callable by authorized updaters
     */
    function updateRiskMetrics(address protocol, RiskMetrics calldata metrics) external;

    /**
     * @notice Returns whether a protocol is considered safe
     * @param protocol The protocol address
     * @return safe Whether the protocol is safe
     */
    function isProtocolSafe(address protocol) external view returns (bool safe);

    /**
     * @notice Returns the recommended maximum allocation for a protocol
     * @param protocol The protocol address
     * @return maxAllocation The maximum allocation in basis points
     */
    function getMaxAllocation(address protocol) external view returns (uint256 maxAllocation);
}
