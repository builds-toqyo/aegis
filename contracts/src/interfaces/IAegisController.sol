// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IAegisController
 * @notice Interface for the Aegis Controller (the "brain" of the system)
 * @dev Manages strategy allocation and rebalancing
 */
interface IAegisController {
    /**
     * @notice Struct representing target allocation for rebalancing
     */
    struct TargetAllocation {
        address strategy;
        uint256 targetAmount;
    }

    /**
     * @notice Rebalances the portfolio according to the target allocation
     * @param targets Array of target allocations
     * @dev Only callable by KEEPER_ROLE
     */
    function rebalance(TargetAllocation[] calldata targets) external;

    /**
     * @notice Adds a new strategy to the controller
     * @param strategy The strategy address
     * @param allocationLimit The maximum allocation percentage (in basis points)
     */
    function addStrategy(address strategy, uint256 allocationLimit) external;

    /**
     * @notice Removes a strategy from the controller
     * @param strategy The strategy address
     */
    function removeStrategy(address strategy) external;

    /**
     * @notice Returns the total assets under management
     * @return The total AUM
     */
    function totalAssets() external view returns (uint256);

    /**
     * @notice Returns all active strategies
     * @return Array of strategy addresses
     */
    function getStrategies() external view returns (address[] memory);

    /**
     * @notice Returns the current allocation for a strategy
     * @param strategy The strategy address
     * @return The current allocation amount
     */
    function strategyAllocation(address strategy) external view returns (uint256);

    /**
     * @notice Harvests yield from all strategies
     * @return The total yield harvested
     */
    function harvestAll() external returns (uint256);

    /**
     * @notice Emergency pause all strategies
     */
    function pauseAll() external;

    /**
     * @notice Resume all strategies
     */
    function unpauseAll() external;
}
