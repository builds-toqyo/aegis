// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/vault/AegisVault.sol";
import "../src/mocks/MockERC20.sol";

/**
 * @title AegisVaultTest
 * @notice Unit tests for AegisVault
 */
contract AegisVaultTest is Test {
    AegisVault public vault;
    MockERC20 public asset;
    
    address public admin = address(1);
    address public treasury = address(2);
    address public user = address(3);

    function setUp() public {
        // Deploy mock asset
        asset = new MockERC20("USD Coin", "USDC", 6);
        
        // Deploy vault
        vault = new AegisVault();
        vault.initialize(
            address(asset),
            "Aegis USDC Vault",
            "aegUSDC",
            admin,
            treasury
        );
    }

    function testInitialization() public {
        assertEq(vault.asset(), address(asset));
        assertEq(vault.treasury(), treasury);
        assertTrue(vault.hasRole(vault.ADMIN_ROLE(), admin));
    }

    // Add more tests here
}
