// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IAegisController.sol";
import "../interfaces/IAegisStrategy.sol";

/**
 * @title AegisController
 * @notice The "brain" of the Aegis system - manages strategy allocation and rebalancing
 * @dev UUPS upgradeable controller that orchestrates fund allocation across strategies
 */
contract AegisController is
    IAegisController,
    AccessControlUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    using SafeERC20 for IERC20;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant KEEPER_ROLE = keccak256("KEEPER_ROLE");
    bytes32 public constant STRATEGIST_ROLE = keccak256("STRATEGIST_ROLE");

    /// @notice The vault contract
    address public vault;

    /// @notice The underlying asset
    address public asset;

    /// @notice Array of active strategies
    address[] private strategies;

    /// @notice Mapping of strategy address to its configuration
    mapping(address => StrategyConfig) public strategyConfigs;

    /// @notice Mapping to check if a strategy is active
    mapping(address => bool) public isActiveStrategy;

    /// @notice Minimum time between rebalances (anti-spam)
    uint256 public minRebalanceInterval;

    /// @notice Last rebalance timestamp
    uint256 public lastRebalance;

    /// @notice Maximum number of strategies
    uint256 public constant MAX_STRATEGIES = 10;

    /// @notice Basis points denominator
    uint256 public constant BASIS_POINTS = 10_000;

    struct StrategyConfig {
        uint256 allocationLimit; // Maximum allocation in basis points
        uint256 currentAllocation; // Current allocation amount
        bool isActive;
        uint256 addedAt;
    }

    event StrategyAdded(address indexed strategy, uint256 allocationLimit);
    event StrategyRemoved(address indexed strategy);
    event Rebalanced(address indexed keeper, uint256 timestamp);
    event StrategyHarvested(address indexed strategy, uint256 yield);
    event EmergencyWithdraw(address indexed strategy, uint256 amount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes the controller
     * @param vault_ The vault address
     * @param asset_ The underlying asset address
     * @param admin_ The admin address
     */
    function initialize(
        address vault_,
        address asset_,
        address admin_
    ) external initializer {
        __AccessControl_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();

        vault = vault_;
        asset = asset_;
        minRebalanceInterval = 1 hours;

        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        _grantRole(ADMIN_ROLE, admin_);
    }

    /**
     * @notice Adds a new strategy
     * @param strategy The strategy address
     * @param allocationLimit The maximum allocation percentage (in basis points)
     */
    function addStrategy(
        address strategy,
        uint256 allocationLimit
    ) external override onlyRole(STRATEGIST_ROLE) {
        require(strategy != address(0), "AegisController: zero address");
        require(!isActiveStrategy[strategy], "AegisController: strategy exists");
        require(strategies.length < MAX_STRATEGIES, "AegisController: max strategies");
        require(allocationLimit <= BASIS_POINTS, "AegisController: invalid limit");

        // Verify strategy implements IAegisStrategy
        require(
            IAegisStrategy(strategy).asset() == asset,
            "AegisController: asset mismatch"
        );

        strategies.push(strategy);
        strategyConfigs[strategy] = StrategyConfig({
            allocationLimit: allocationLimit,
            currentAllocation: 0,
            isActive: true,
            addedAt: block.timestamp
        });
        isActiveStrategy[strategy] = true;

        emit StrategyAdded(strategy, allocationLimit);
    }

    /**
     * @notice Removes a strategy
     * @param strategy The strategy address
     */
    function removeStrategy(address strategy) external override onlyRole(ADMIN_ROLE) {
        require(isActiveStrategy[strategy], "AegisController: strategy not active");

        // Withdraw all funds from the strategy
        StrategyConfig storage config = strategyConfigs[strategy];
        if (config.currentAllocation > 0) {
            uint256 withdrawn = IAegisStrategy(strategy).withdraw(config.currentAllocation);
            IERC20(asset).safeTransfer(vault, withdrawn);
            config.currentAllocation = 0;
        }

        // Remove from array
        for (uint256 i = 0; i < strategies.length; i++) {
            if (strategies[i] == strategy) {
                strategies[i] = strategies[strategies.length - 1];
                strategies.pop();
                break;
            }
        }

        config.isActive = false;
        isActiveStrategy[strategy] = false;

        emit StrategyRemoved(strategy);
    }

    /**
     * @notice Rebalances the portfolio according to target allocation
     * @param targets Array of target allocations
     * @dev Only callable by KEEPER_ROLE
     */
    function rebalance(
        TargetAllocation[] calldata targets
    ) external override onlyRole(KEEPER_ROLE) whenNotPaused nonReentrant {
        require(
            block.timestamp >= lastRebalance + minRebalanceInterval,
            "AegisController: too soon"
        );

        // Validate targets
        uint256 totalTargetAllocation = 0;
        for (uint256 i = 0; i < targets.length; i++) {
            require(
                isActiveStrategy[targets[i].strategy],
                "AegisController: invalid strategy"
            );
            totalTargetAllocation += targets[i].targetAmount;
        }

        // Execute rebalancing
        for (uint256 i = 0; i < targets.length; i++) {
            address strategy = targets[i].strategy;
            uint256 targetAmount = targets[i].targetAmount;
            StrategyConfig storage config = strategyConfigs[strategy];

            // Check allocation limit
            uint256 totalAssets = totalAssets();
            uint256 maxAllocation = (totalAssets * config.allocationLimit) / BASIS_POINTS;
            require(targetAmount <= maxAllocation, "AegisController: exceeds limit");

            uint256 currentAmount = config.currentAllocation;

            if (targetAmount > currentAmount) {
                // Deposit more
                uint256 toDeposit = targetAmount - currentAmount;
                _depositToStrategy(strategy, toDeposit);
            } else if (targetAmount < currentAmount) {
                // Withdraw excess
                uint256 toWithdraw = currentAmount - targetAmount;
                _withdrawFromStrategy(strategy, toWithdraw);
            }

            config.currentAllocation = targetAmount;
        }

        lastRebalance = block.timestamp;
        emit Rebalanced(msg.sender, block.timestamp);
    }

    /**
     * @notice Harvests yield from all strategies
     * @return totalYield The total yield harvested
     */
    function harvestAll() external override onlyRole(KEEPER_ROLE) returns (uint256 totalYield) {
        for (uint256 i = 0; i < strategies.length; i++) {
            address strategy = strategies[i];
            if (isActiveStrategy[strategy]) {
                try IAegisStrategy(strategy).harvest() returns (uint256 yield) {
                    totalYield += yield;
                    emit StrategyHarvested(strategy, yield);
                } catch {
                    // Continue harvesting other strategies
                    continue;
                }
            }
        }
    }

    /**
     * @notice Returns the total assets under management
     * @return total The total AUM
     */
    function totalAssets() public view override returns (uint256 total) {
        // Assets in vault
        total = IERC20(asset).balanceOf(vault);

        // Assets in controller
        total += IERC20(asset).balanceOf(address(this));

        // Assets in strategies
        for (uint256 i = 0; i < strategies.length; i++) {
            if (isActiveStrategy[strategies[i]]) {
                total += IAegisStrategy(strategies[i]).totalAssets();
            }
        }
    }

    /**
     * @notice Returns all active strategies
     * @return Array of strategy addresses
     */
    function getStrategies() external view override returns (address[] memory) {
        return strategies;
    }

    /**
     * @notice Returns the current allocation for a strategy
     * @param strategy The strategy address
     * @return The current allocation amount
     */
    function strategyAllocation(
        address strategy
    ) external view override returns (uint256) {
        return strategyConfigs[strategy].currentAllocation;
    }

    /**
     * @notice Emergency pause all strategies
     */
    function pauseAll() external override onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /**
     * @notice Resume all strategies
     */
    function unpauseAll() external override onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @notice Emergency withdraw from a strategy
     * @param strategy The strategy address
     */
    function emergencyWithdraw(address strategy) external onlyRole(ADMIN_ROLE) {
        require(isActiveStrategy[strategy], "AegisController: invalid strategy");

        IAegisStrategy(strategy).emergencyWithdraw();
        uint256 balance = IERC20(asset).balanceOf(address(this));
        if (balance > 0) {
            IERC20(asset).safeTransfer(vault, balance);
        }

        strategyConfigs[strategy].currentAllocation = 0;
        emit EmergencyWithdraw(strategy, balance);
    }

    /**
     * @notice Sets the minimum rebalance interval
     * @param interval The new interval in seconds
     */
    function setMinRebalanceInterval(uint256 interval) external onlyRole(ADMIN_ROLE) {
        minRebalanceInterval = interval;
    }

    /**
     * @notice Deposits assets to a strategy
     * @param strategy The strategy address
     * @param amount The amount to deposit
     */
    function _depositToStrategy(address strategy, uint256 amount) internal {
        // Request funds from vault
        (bool success, ) = vault.call(
            abi.encodeWithSignature("transferToController(uint256)", amount)
        );
        require(success, "AegisController: vault transfer failed");

        // Approve and deposit to strategy
        IERC20(asset).safeApprove(strategy, amount);
        IAegisStrategy(strategy).deposit(amount);
    }

    /**
     * @notice Withdraws assets from a strategy
     * @param strategy The strategy address
     * @param amount The amount to withdraw
     */
    function _withdrawFromStrategy(address strategy, uint256 amount) internal {
        uint256 withdrawn = IAegisStrategy(strategy).withdraw(amount);
        IERC20(asset).safeTransfer(vault, withdrawn);
    }

    /**
     * @notice Authorizes an upgrade
     * @param newImplementation The new implementation address
     */
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(ADMIN_ROLE) {}
}
