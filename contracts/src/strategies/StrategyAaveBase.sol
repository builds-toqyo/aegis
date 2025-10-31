// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./BaseStrategy.sol";

/**
 * @title StrategyAaveBase
 * @notice Strategy for lending assets on Aave v3 on Base L2
 * @dev Deposits assets into Aave and earns lending yield
 */
contract StrategyAaveBase is BaseStrategy {
    /// @notice Aave Pool address on Base
    address public aavePool;

    /// @notice aToken received from Aave
    address public aToken;

    /// @notice Current APY (cached, updated periodically)
    uint256 private _currentAPY;

    /// @notice Risk score (0-100)
    uint256 private constant RISK_SCORE = 25; // Low risk

    event AavePoolUpdated(address indexed oldPool, address indexed newPool);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes the Aave strategy
     * @param asset_ The underlying asset
     * @param controller_ The controller address
     * @param admin_ The admin address
     * @param aavePool_ The Aave pool address
     * @param aToken_ The aToken address
     */
    function initialize(
        address asset_,
        address controller_,
        address admin_,
        address aavePool_,
        address aToken_
    ) external initializer {
        __BaseStrategy_init(asset_, controller_, admin_, "Aave Base Lending");
        
        aavePool = aavePool_;
        aToken = aToken_;
        _currentAPY = 300; // 3% default
    }

    /**
     * @notice Returns the current APY
     * @return The APY in basis points
     */
    function currentAPY() external view override returns (uint256) {
        return _currentAPY;
    }

    /**
     * @notice Returns the risk score
     * @return The risk score (0-100)
     */
    function riskScore() external pure override returns (uint256) {
        return RISK_SCORE;
    }

    /**
     * @notice Returns available liquidity
     * @return The available liquidity
     */
    function availableLiquidity() external view override returns (uint256) {
        // In Aave, liquidity is typically high
        return IERC20(aToken).balanceOf(address(this));
    }

    /**
     * @notice Updates the APY (called by keeper or oracle)
     * @param newAPY The new APY in basis points
     */
    function updateAPY(uint256 newAPY) external onlyRole(CONTROLLER_ROLE) {
        _currentAPY = newAPY;
    }

    /**
     * @notice Internal deposit logic
     * @param amount The amount to deposit
     * @return The actual amount deposited
     */
    function _deposit(uint256 amount) internal override returns (uint256) {
        // Approve Aave pool
        IERC20(asset).safeApprove(aavePool, amount);

        // Deposit to Aave
        // Note: In production, use actual Aave interface
        (bool success, ) = aavePool.call(
            abi.encodeWithSignature(
                "supply(address,uint256,address,uint16)",
                asset,
                amount,
                address(this),
                0
            )
        );
        require(success, "StrategyAaveBase: deposit failed");

        return amount;
    }

    /**
     * @notice Internal withdraw logic
     * @param amount The amount to withdraw
     * @return The actual amount withdrawn
     */
    function _withdraw(uint256 amount) internal override returns (uint256) {
        // Withdraw from Aave
        (bool success, bytes memory data) = aavePool.call(
            abi.encodeWithSignature(
                "withdraw(address,uint256,address)",
                asset,
                amount,
                address(this)
            )
        );
        require(success, "StrategyAaveBase: withdraw failed");

        uint256 withdrawn = abi.decode(data, (uint256));
        return withdrawn;
    }

    /**
     * @notice Internal harvest logic
     * @return The amount of yield harvested
     */
    function _harvest() internal override returns (uint256) {
        // Calculate accrued interest
        uint256 currentBalance = IERC20(aToken).balanceOf(address(this));
        
        if (currentBalance > _totalAssets) {
            return currentBalance - _totalAssets;
        }
        
        return 0;
    }

    /**
     * @notice Internal emergency withdraw logic
     * @return The amount withdrawn
     */
    function _emergencyWithdraw() internal override returns (uint256) {
        uint256 balance = IERC20(aToken).balanceOf(address(this));
        
        if (balance > 0) {
            return _withdraw(balance);
        }
        
        return 0;
    }

    /**
     * @notice Sets the Aave pool address
     * @param newPool The new pool address
     */
    function setAavePool(address newPool) external onlyRole(ADMIN_ROLE) {
        require(newPool != address(0), "StrategyAaveBase: zero address");
        address oldPool = aavePool;
        aavePool = newPool;
        emit AavePoolUpdated(oldPool, newPool);
    }
}
