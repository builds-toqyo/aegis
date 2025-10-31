// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IBridge
 * @notice Interface for cross-chain bridge operations (Base <-> Ethereum L1)
 * @dev Used by satellite strategies like StrategyLidoL1
 */
interface IBridge {
    /**
     * @notice Bridges assets from Base to Ethereum L1
     * @param amount The amount to bridge
     * @param recipient The recipient address on L1
     * @param minGasLimit The minimum gas limit for L1 execution
     */
    function bridgeToL1(
        uint256 amount,
        address recipient,
        uint32 minGasLimit
    ) external payable;

    /**
     * @notice Bridges assets from Ethereum L1 to Base
     * @param amount The amount to bridge
     * @param recipient The recipient address on Base
     */
    function bridgeToL2(uint256 amount, address recipient) external payable;

    /**
     * @notice Returns the estimated bridge fee
     * @param amount The amount to bridge
     * @return The estimated fee
     */
    function estimateBridgeFee(uint256 amount) external view returns (uint256);

    /**
     * @notice Returns the bridge status for a transaction
     * @param txHash The transaction hash
     * @return completed Whether the bridge is completed
     */
    function bridgeStatus(bytes32 txHash) external view returns (bool completed);
}
