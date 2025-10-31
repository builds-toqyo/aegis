// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IBridge.sol";

/**
 * @title MockBridge
 * @notice Mock bridge contract for testing cross-chain operations
 */
contract MockBridge is IBridge {
    mapping(bytes32 => bool) private _bridgeStatus;
    uint256 private _bridgeFee;

    event BridgedToL1(address indexed sender, uint256 amount, address recipient);
    event BridgedToL2(address indexed sender, uint256 amount, address recipient);

    constructor(uint256 bridgeFee) {
        _bridgeFee = bridgeFee;
    }

    function bridgeToL1(
        uint256 amount,
        address recipient,
        uint32 /* minGasLimit */
    ) external payable override {
        require(msg.value >= _bridgeFee, "MockBridge: insufficient fee");
        
        bytes32 txHash = keccak256(abi.encodePacked(msg.sender, amount, recipient, block.timestamp));
        _bridgeStatus[txHash] = true;
        
        emit BridgedToL1(msg.sender, amount, recipient);
    }

    function bridgeToL2(uint256 amount, address recipient) external payable override {
        require(msg.value >= _bridgeFee, "MockBridge: insufficient fee");
        
        bytes32 txHash = keccak256(abi.encodePacked(msg.sender, amount, recipient, block.timestamp));
        _bridgeStatus[txHash] = true;
        
        emit BridgedToL2(msg.sender, amount, recipient);
    }

    function estimateBridgeFee(uint256) external view override returns (uint256) {
        return _bridgeFee;
    }

    function bridgeStatus(bytes32 txHash) external view override returns (bool completed) {
        return _bridgeStatus[txHash];
    }

    function setBridgeFee(uint256 newFee) external {
        _bridgeFee = newFee;
    }
}
