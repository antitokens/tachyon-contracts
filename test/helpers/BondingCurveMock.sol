// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../../src/BondingCurve.sol";

contract BondingCurveMock is BondingCurve {
    uint32 constant RESERVE_RATIO = 333333; // 1/3 in ppm (parts per million)

    constructor()
        payable
        BondingCurve(
            "BondingCurveMock",
            "BCM",
            RESERVE_RATIO,
            msg.sender // dev account
        )
    {}

    // Helper function to set initial state for testing
    function setInitialState(uint256 initialSupply, uint256 initialPoolBalance) external {
        _mint(msg.sender, initialSupply);
        poolBalance = initialPoolBalance;
    }

    // Test helper functions for internal functions
    function powerTest(uint256 baseN, uint256 baseD, uint32 expN, uint32 expD) public view returns (uint256, uint8) {
        return power(baseN, baseD, expN, expD);
    }

    function lnTest(uint256 numerator, uint256 denominator) public pure returns (uint256) {
        return ln(numerator, denominator);
    }

    function findPositionInMaxExpArrayTest(uint256 x) public view returns (uint8) {
        return findPositionInMaxExpArray(x);
    }

    function fixedExpTest(uint256 x, uint8 precision) public pure returns (uint256) {
        return fixedExp(x, precision);
    }

    function floorLog2Test(uint256 n) public pure returns (uint8) {
        return floorLog2(n);
    }
}
