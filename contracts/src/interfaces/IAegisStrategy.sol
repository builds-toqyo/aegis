// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IAegisStrategy
 * @notice Interface for all Aegis yield strategies
 * @dev All strategies must implement this interface to be compatible with AegisController
 */
interface IAegisStrategy {
    /**
     * @notice Deposits assets into the strategy
     * @param amount The amount of assets to deposit
     * @return The actual amount deposited
     */
    function deposit(uint256 amount) external returns (uint256);

    /**
     * @notice Withdraws assets from the strategy
     * @param amount The amount of assets to withdraw
     * @return The actual amount withdrawn
     */
    function withdraw(uint256 amount) external returns (uint256);

    /**
     * @notice Returns the total value of assets managed by this strategy
     * @return The total assets in the underlying asset denomination
     */
    function totalAssets() external view returns (uint256);

    /**
     * @notice Returns the available liquidity that can be withdrawn immediately
     * @return The available liquidity
     */
    function availableLiquidity() external view returns (uint256);

    /**
     * @notice Harvests yield and compounds rewards
     * @return The amount of yield harvested
     */
    function harvest() external returns (uint256);

    /**
     * @notice Returns the current APY of the strategy (in basis points)
     * @return The APY in basis points (e.g., 500 = 5%)
     */
    function currentAPY() external view returns (uint256);

    /**
     * @notice Returns the risk score of the strategy (0-100)
     * @return The risk score
     */
    function riskScore() external view returns (uint256);

    /**
     * @notice Returns the underlying asset address
     * @return The asset address
     */
    function asset() external view returns (address);

    /**
     * @notice Emergency withdraw all funds
     * @dev Only callable by authorized roles
     */
    function emergencyWithdraw() external;

    /**
     * @notice Returns the strategy name
     * @return The strategy name
     */
    function name() external view returns (string memory);
}
