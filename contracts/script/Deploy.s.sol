// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/vault/AegisVault.sol";
import "../src/vault/AegisController.sol";
import "../src/strategies/StrategyAaveBase.sol";

/**
 * @title Deploy
 * @notice Deployment script for Aegis Yield contracts
 */
contract Deploy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy contracts here
        console.log("Deploying Aegis Yield contracts...");
        console.log("Deployer:", deployer);

        // TODO: Add actual deployment logic

        vm.stopBroadcast();
    }
}
