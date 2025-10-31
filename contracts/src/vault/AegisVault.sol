// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title AegisVault
 * @notice ERC-4626 compliant vault for dynamic yield optimization
 * @dev UUPS upgradeable vault that delegates strategy management to AegisController
 */
contract AegisVault is
    ERC4626Upgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    using SafeERC20 for IERC20;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant CONTROLLER_ROLE = keccak256("CONTROLLER_ROLE");

    /// @notice The controller contract that manages strategies
    address public controller;

    /// @notice Performance fee in basis points (e.g., 1000 = 10%)
    uint256 public performanceFee;

    /// @notice Management fee in basis points per year
    uint256 public managementFee;

    /// @notice Treasury address for fee collection
    address public treasury;

    /// @notice Last fee collection timestamp
    uint256 public lastFeeCollection;

    /// @notice Maximum performance fee (20%)
    uint256 public constant MAX_PERFORMANCE_FEE = 2000;

    /// @notice Maximum management fee (2% per year)
    uint256 public constant MAX_MANAGEMENT_FEE = 200;

    /// @notice Basis points denominator
    uint256 public constant BASIS_POINTS = 10_000;

    event ControllerUpdated(address indexed oldController, address indexed newController);
    event PerformanceFeeUpdated(uint256 oldFee, uint256 newFee);
    event ManagementFeeUpdated(uint256 oldFee, uint256 newFee);
    event TreasuryUpdated(address indexed oldTreasury, address indexed newTreasury);
    event FeesCollected(uint256 performanceFees, uint256 managementFees);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes the vault
     * @param asset_ The underlying asset address
     * @param name_ The vault token name
     * @param symbol_ The vault token symbol
     * @param admin_ The admin address
     * @param treasury_ The treasury address
     */
    function initialize(
        address asset_,
        string memory name_,
        string memory symbol_,
        address admin_,
        address treasury_
    ) external initializer {
        __ERC4626_init(IERC20(asset_));
        __ERC20_init(name_, symbol_);
        __AccessControl_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        _grantRole(ADMIN_ROLE, admin_);

        treasury = treasury_;
        performanceFee = 1000; // 10% default
        managementFee = 100; // 1% per year default
        lastFeeCollection = block.timestamp;
    }

    /**
     * @notice Sets the controller address
     * @param newController The new controller address
     */
    function setController(address newController) external onlyRole(ADMIN_ROLE) {
        require(newController != address(0), "AegisVault: zero address");
        address oldController = controller;
        controller = newController;
        _grantRole(CONTROLLER_ROLE, newController);
        if (oldController != address(0)) {
            _revokeRole(CONTROLLER_ROLE, oldController);
        }
        emit ControllerUpdated(oldController, newController);
    }

    /**
     * @notice Sets the performance fee
     * @param newFee The new performance fee in basis points
     */
    function setPerformanceFee(uint256 newFee) external onlyRole(ADMIN_ROLE) {
        require(newFee <= MAX_PERFORMANCE_FEE, "AegisVault: fee too high");
        uint256 oldFee = performanceFee;
        performanceFee = newFee;
        emit PerformanceFeeUpdated(oldFee, newFee);
    }

    /**
     * @notice Sets the management fee
     * @param newFee The new management fee in basis points per year
     */
    function setManagementFee(uint256 newFee) external onlyRole(ADMIN_ROLE) {
        require(newFee <= MAX_MANAGEMENT_FEE, "AegisVault: fee too high");
        uint256 oldFee = managementFee;
        managementFee = newFee;
        emit ManagementFeeUpdated(oldFee, newFee);
    }

    /**
     * @notice Sets the treasury address
     * @param newTreasury The new treasury address
     */
    function setTreasury(address newTreasury) external onlyRole(ADMIN_ROLE) {
        require(newTreasury != address(0), "AegisVault: zero address");
        address oldTreasury = treasury;
        treasury = newTreasury;
        emit TreasuryUpdated(oldTreasury, newTreasury);
    }

    /**
     * @notice Pauses the vault
     */
    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /**
     * @notice Unpauses the vault
     */
    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @notice Returns the total assets under management
     * @dev Queries the controller for total assets across all strategies
     */
    function totalAssets() public view virtual override returns (uint256) {
        if (controller == address(0)) {
            return IERC20(asset()).balanceOf(address(this));
        }
        
        // Call controller to get total assets across all strategies
        (bool success, bytes memory data) = controller.staticcall(
            abi.encodeWithSignature("totalAssets()")
        );
        
        if (success && data.length >= 32) {
            return abi.decode(data, (uint256));
        }
        
        return IERC20(asset()).balanceOf(address(this));
    }

    /**
     * @notice Collects performance and management fees
     * @dev Can be called by anyone, fees are minted as vault shares to treasury
     */
    function collectFees() external nonReentrant {
        uint256 currentAssets = totalAssets();
        uint256 currentShares = totalSupply();
        
        if (currentShares == 0) {
            lastFeeCollection = block.timestamp;
            return;
        }

        // Calculate management fees based on time elapsed
        uint256 timeElapsed = block.timestamp - lastFeeCollection;
        uint256 managementFees = (currentAssets * managementFee * timeElapsed) /
            (BASIS_POINTS * 365 days);

        // Performance fees are calculated on gains
        uint256 performanceFees = 0;
        uint256 expectedAssets = convertToAssets(currentShares);
        if (currentAssets > expectedAssets) {
            uint256 profit = currentAssets - expectedAssets;
            performanceFees = (profit * performanceFee) / BASIS_POINTS;
        }

        uint256 totalFees = managementFees + performanceFees;
        if (totalFees > 0) {
            uint256 feeShares = convertToShares(totalFees);
            _mint(treasury, feeShares);
            emit FeesCollected(performanceFees, managementFees);
        }

        lastFeeCollection = block.timestamp;
    }

    /**
     * @notice Deposits assets into the vault
     * @dev Overridden to add pause and reentrancy protection
     */
    function deposit(
        uint256 assets,
        address receiver
    ) public virtual override whenNotPaused nonReentrant returns (uint256) {
        return super.deposit(assets, receiver);
    }

    /**
     * @notice Mints shares from the vault
     * @dev Overridden to add pause and reentrancy protection
     */
    function mint(
        uint256 shares,
        address receiver
    ) public virtual override whenNotPaused nonReentrant returns (uint256) {
        return super.mint(shares, receiver);
    }

    /**
     * @notice Withdraws assets from the vault
     * @dev Overridden to add pause and reentrancy protection
     */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual override whenNotPaused nonReentrant returns (uint256) {
        return super.withdraw(assets, receiver, owner);
    }

    /**
     * @notice Redeems shares from the vault
     * @dev Overridden to add pause and reentrancy protection
     */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public virtual override whenNotPaused nonReentrant returns (uint256) {
        return super.redeem(shares, receiver, owner);
    }

    /**
     * @notice Transfers assets to the controller for strategy deployment
     * @param amount The amount to transfer
     * @dev Only callable by the controller
     */
    function transferToController(uint256 amount) external onlyRole(CONTROLLER_ROLE) {
        IERC20(asset()).safeTransfer(controller, amount);
    }

    /**
     * @notice Authorizes an upgrade
     * @param newImplementation The new implementation address
     */
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(ADMIN_ROLE) {}
}
