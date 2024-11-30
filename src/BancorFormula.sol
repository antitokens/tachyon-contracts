// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Power.sol";

/**
 * @title Bancor Formula
 * @dev Modified Bancor formula for Solidity 0.8.x with built-in overflow checks.
 */
contract BancorFormula is Power {
    string public constant VERSION = "0.1";
    uint32 private constant MAX_WEIGHT = 1_000_000;
    uint256 private constant FEE_PERCENTAGE = 100; // 1% = 1/10000 = 100ppm

    address public devAccount; // Developer's account to collect fees

    /**
     * @dev Constructor to initialize the dev account
     * @param _devAccount The developer account address that will receive the fees
     */
    constructor(address _devAccount) {
        require(_devAccount != address(0), "INVALID_ADDRESS");
        devAccount = _devAccount;
    }

    /**
     * @dev Calculates the return for a given purchase.
     *
     * Formula: Return = supply  ((1 + depositAmount / connectorBalance) ^ (connectorWeight / 1000000) - 1)
     */
    function calculatePurchaseReturn(
        uint256 _supply,
        uint256 _connectorBalance,
        uint32 _connectorWeight,
        uint256 _depositAmount
    ) public view returns (uint256) {
        require(
            _supply > 0 && 
            _connectorBalance > 0 && 
            _connectorWeight > 0 && 
            _connectorWeight <= MAX_WEIGHT,
            "INVALID_INPUT"
        );

        if (_depositAmount == 0) {
            return 0;
        }

        if (_connectorWeight == MAX_WEIGHT) {
            return (_supply * _depositAmount) / _connectorBalance;
        }

        uint256 result;
        uint8 precision;
        uint256 baseN = _depositAmount + _connectorBalance;
        (result, precision) = power(baseN, _connectorBalance, _connectorWeight, MAX_WEIGHT);
        uint256 temp = (_supply * result) >> precision;
        return temp - _supply;
    }

    /**
     * @dev Calculates the return for a given sale.
     *
     * Formula: Return = connectorBalance  (1 - (1 - sellAmount / supply) ^ (1 / (connectorWeight / 1000000)))
     */
    function calculateSaleReturn(
        uint256 _supply,
        uint256 _connectorBalance,
        uint32 _connectorWeight,
        uint256 _sellAmount
    ) public view returns (uint256) {
        require(
            _supply > 0 &&
            _connectorBalance > 0 &&
            _connectorWeight > 0 &&
            _connectorWeight <= MAX_WEIGHT &&
            _sellAmount <= _supply,
            "INVALID_INPUT"
        );

        if (_sellAmount == 0) {
            return 0;
        }

        if (_sellAmount == _supply) {
            return _connectorBalance;
        }

        if (_connectorWeight == MAX_WEIGHT) {
            return (_connectorBalance * _sellAmount) / _supply;
        }

        uint256 result;
        uint8 precision;
        uint256 baseD = _supply - _sellAmount;
        (result, precision) = power(_supply, baseD, MAX_WEIGHT, _connectorWeight);
        uint256 oldBalance = _connectorBalance * result;
        uint256 newBalance = _connectorBalance << precision;
        return (oldBalance - newBalance) / result;
    }

    /**
     * @dev Helper to apply a fee to any amount
     * @param _amount The input amount to apply fee to
     * @return The amount after fee deduction
     */
    function applyFee(uint256 _amount) internal pure returns (uint256) {
        return (_amount * (10000 - FEE_PERCENTAGE)) / 10000;
    }
}