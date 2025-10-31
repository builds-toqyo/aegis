// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IAegisStrategy.sol";

/**
 * @title BaseStrategy
 * @notice Abstract base contract for all Aegis strategies
 * @dev Provides common functionality and security features
 */
abstract contract BaseStrategy is
    IAegisStrategy,
    AccessControlUpgradeable,
    PausableUpgradeable,
    ReentrancyGuard
{
    using SafeERC20 for IERC20;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant CONTROLLER_ROLE = keccak256("CONTROLLER_ROLE");

    /// @notice The underlying asset
    address public override asset;

    /// @notice The controller address
    address public controller;

    /// @notice Strategy name
    string public override name;

    /// @notice Total assets deposited
    uint256 internal _totalAssets;

    event Deposited(uint256 amount);
    event Withdrawn(uint256 amount);
    event Harvested(uint256 yield);
    event EmergencyExit(uint256 amount);

    modifier onlyController() {
        require(hasRole(CONTROLLER_ROLE, msg.sender), "BaseStrategy: not controller");
        _;
    }

    /**
     * @notice Initializes the base strategy
     * @param asset_ The underlying asset
     * @param controller_ The controller address
     * @param name_ The strategy name
     */
    function __BaseStrategy_init(
        address asset_,
        address controller_,
        string memory name_
    ) internal onlyInitializing {
        __AccessControl_init();
        __Pausable_init();

        asset = asset_;
        controller = controller_;
        name = name_;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(CONTROLLER_ROLE, controller_);
    }

    /**
     * @notice Deposits assets into the strategy
     * @param amount The amount to deposit
     * @return The actual amount deposited
     */
    function deposit(
        uint256 amount
    ) external virtual override onlyController whenNotPaused nonReentrant returns (uint256) {
        require(amount > 0, "BaseStrategy: zero amount");

        IERC20(asset).safeTransferFrom(controller, address(this), amount);
        
        uint256 deposited = _deposit(amount);
        _totalAssets += deposited;

        emit Deposited(deposited);
        return deposited;
    }

    /**
     * @notice Withdraws assets from the strategy
     * @param amount The amount to withdraw
     * @return The actual amount withdrawn
     */
    function withdraw(
        uint256 amount
    ) external virtual override onlyController nonReentrant returns (uint256) {
        require(amount > 0, "BaseStrategy: zero amount");
        require(amount <= _totalAssets, "BaseStrategy: insufficient balance");

        uint256 withdrawn = _withdraw(amount);
        _totalAssets -= withdrawn;

        IERC20(asset).safeTransfer(controller, withdrawn);

        emit Withdrawn(withdrawn);
        return withdrawn;
    }

    /**
     * @notice Returns the total assets managed by this strategy
     * @return The total assets
     */
    function totalAssets() external view virtual override returns (uint256) {
        return _totalAssets;
    }

    /**
     * @notice Harvests yield and compounds rewards
     * @return The amount of yield harvested
     */
    function harvest() external virtual override onlyController returns (uint256) {
        uint256 yield = _harvest();
        if (yield > 0) {
            _totalAssets += yield;
            emit Harvested(yield);
        }
        return yield;
    }

    /**
     * @notice Emergency withdraw all funds
     */
    function emergencyWithdraw() external virtual override onlyRole(ADMIN_ROLE) {
        _pause();
        uint256 amount = _emergencyWithdraw();
        
        if (amount > 0) {
            IERC20(asset).safeTransfer(controller, amount);
        }

        _totalAssets = 0;
        emit EmergencyExit(amount);
    }

    /**
     * @notice Pauses the strategy
     */
    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /**
     * @notice Unpauses the strategy
     */
    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    // Internal functions to be implemented by specific strategies

    /**
     * @notice Internal deposit logic
     * @param amount The amount to deposit
     * @return The actual amount deposited
     */
    function _deposit(uint256 amount) internal virtual returns (uint256);

    /**
     * @notice Internal withdraw logic
     * @param amount The amount to withdraw
     * @return The actual amount withdrawn
     */
    function _withdraw(uint256 amount) internal virtual returns (uint256);

    /**
     * @notice Internal harvest logic
     * @return The amount of yield harvested
     */
    function _harvest() internal virtual returns (uint256);

    /**
     * @notice Internal emergency withdraw logic
     * @return The amount withdrawn
     */
    function _emergencyWithdraw() internal virtual returns (uint256);
}
