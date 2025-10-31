// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../src/vault/AegisVault.sol";
import "../src/vault/AegisController.sol";
import "../src/strategies/StrategyAaveBase.sol";

/**
 * @title Deploy
 * @notice Deployment script for Aegis Yield contracts with UUPS proxies
 * @dev Deploys implementation contracts, proxies, and initializes with proper roles
 */
contract Deploy is Script {
    // Deployment addresses (will be set during deployment)
    address public vaultImplementation;
    address public vaultProxy;
    address public controllerImplementation;
    address public controllerProxy;
    address public aaveStrategy;

    // Role identifiers
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 public constant KEEPER_ROLE = keccak256("KEEPER_ROLE");
    bytes32 public constant STRATEGIST_ROLE = keccak256("STRATEGIST_ROLE");

    function run() external {
        // Load environment variables
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        address keeperEOA = vm.envAddress("KEEPER_ADDRESS");
        address adminMultisig = vm.envOr("ADMIN_MULTISIG", deployer);
        address strategistMultisig = vm.envOr("STRATEGIST_MULTISIG", deployer);
        address asset = vm.envAddress("VAULT_ASSET"); // USDC on Base

        console.log("=== Aegis Yield Deployment ===");
        console.log("Network: Base (Chain ID: 8453)");
        console.log("Deployer:", deployer);
        console.log("Keeper EOA:", keeperEOA);
        console.log("Admin Multisig:", adminMultisig);
        console.log("Vault Asset:", asset);
        console.log("");

        vm.startBroadcast(deployerPrivateKey);

        // ============================================
        // 1. Deploy Controller Implementation
        // ============================================
        console.log("1. Deploying AegisController implementation...");
        controllerImplementation = address(new AegisController());
        console.log("   Controller Implementation:", controllerImplementation);

        // ============================================
        // 2. Deploy Controller Proxy
        // ============================================
        console.log("2. Deploying AegisController proxy...");
        bytes memory controllerInitData = abi.encodeWithSelector(
            AegisController.initialize.selector,
            deployer // Initial admin (will transfer to multisig later)
        );
        controllerProxy = address(new ERC1967Proxy(controllerImplementation, controllerInitData));
        console.log("   Controller Proxy:", controllerProxy);

        // ============================================
        // 3. Deploy Vault Implementation
        // ============================================
        console.log("3. Deploying AegisVault implementation...");
        vaultImplementation = address(new AegisVault());
        console.log("   Vault Implementation:", vaultImplementation);

        // ============================================
        // 4. Deploy Vault Proxy
        // ============================================
        console.log("4. Deploying AegisVault proxy...");
        bytes memory vaultInitData = abi.encodeWithSelector(
            AegisVault.initialize.selector,
            IERC20(asset),
            "Aegis Yield Vault",
            "aegUSDC",
            controllerProxy,
            deployer // Initial admin
        );
        vaultProxy = address(new ERC1967Proxy(vaultImplementation, vaultInitData));
        console.log("   Vault Proxy:", vaultProxy);

        // ============================================
        // 5. Deploy Aave Strategy
        // ============================================
        console.log("5. Deploying StrategyAaveBase...");
        address aavePool = vm.envAddress("AAVE_POOL_ADDRESS");
        aaveStrategy = address(new StrategyAaveBase(
            IERC20(asset),
            controllerProxy,
            aavePool,
            "Aave USDC Strategy"
        ));
        console.log("   Aave Strategy:", aaveStrategy);

        // ============================================
        // 6. Configure Roles on Controller
        // ============================================
        console.log("6. Configuring roles...");
        AegisController controller = AegisController(controllerProxy);
        
        // Grant KEEPER_ROLE to keeper bot EOA
        controller.grantRole(KEEPER_ROLE, keeperEOA);
        console.log("   Granted KEEPER_ROLE to:", keeperEOA);
        
        // Grant STRATEGIST_ROLE to strategist multisig
        controller.grantRole(STRATEGIST_ROLE, strategistMultisig);
        console.log("   Granted STRATEGIST_ROLE to:", strategistMultisig);

        // ============================================
        // 7. Add Strategy to Controller
        // ============================================
        console.log("7. Adding Aave strategy to controller...");
        controller.addStrategy(aaveStrategy, 5000); // 50% max allocation
        console.log("   Strategy added with 50% cap");

        // ============================================
        // 8. Transfer Admin Role to Multisig
        // ============================================
        if (adminMultisig != deployer) {
            console.log("8. Transferring admin role to multisig...");
            controller.grantRole(DEFAULT_ADMIN_ROLE, adminMultisig);
            controller.renounceRole(DEFAULT_ADMIN_ROLE, deployer);
            console.log("   Admin role transferred to:", adminMultisig);
        }

        vm.stopBroadcast();

        // ============================================
        // 9. Save Deployment Artifacts
        // ============================================
        console.log("");
        console.log("=== Deployment Complete ===");
        console.log("Save these addresses for the Go backend:");
        console.log("");
        
        _writeDeploymentArtifacts(
            deployer,
            keeperEOA,
            adminMultisig,
            asset
        );
    }

    /**
     * @notice Writes deployment artifacts to JSON file for Go backend
     */
    function _writeDeploymentArtifacts(
        address deployer,
        address keeperEOA,
        address adminMultisig,
        address asset
    ) internal {
        string memory json = "deployment";
        
        // Network info
        vm.serializeString(json, "network", "base");
        vm.serializeUint(json, "chainId", 8453);
        
        // Contract addresses
        vm.serializeAddress(json, "vaultImplementation", vaultImplementation);
        vm.serializeAddress(json, "vaultProxy", vaultProxy);
        vm.serializeAddress(json, "controllerImplementation", controllerImplementation);
        vm.serializeAddress(json, "controllerProxy", controllerProxy);
        vm.serializeAddress(json, "aaveStrategy", aaveStrategy);
        
        // Configuration
        vm.serializeAddress(json, "asset", asset);
        vm.serializeAddress(json, "deployer", deployer);
        vm.serializeAddress(json, "keeperEOA", keeperEOA);
        vm.serializeAddress(json, "adminMultisig", adminMultisig);
        
        // Roles (as hex strings)
        vm.serializeBytes32(json, "DEFAULT_ADMIN_ROLE", DEFAULT_ADMIN_ROLE);
        vm.serializeBytes32(json, "KEEPER_ROLE", KEEPER_ROLE);
        string memory finalJson = vm.serializeBytes32(json, "STRATEGIST_ROLE", STRATEGIST_ROLE);
        
        // Write to file
        string memory outputPath = "./deployments/base-deployment.json";
        vm.writeJson(finalJson, outputPath);
        
        console.log("Deployment artifacts written to:", outputPath);
    }
}
