// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../../src/BondingCurve.sol";

contract BondingCurveMock is BondingCurve {
    uint32 constant RESERVE_RATIO = 333333; // 1/3 in ppm (parts per million)
    uint256 public totalSupply_;
    mapping(address => uint256) public balances;

    constructor() payable BondingCurve("BondingCurveMock", "BCM", msg.sender) {
        reserveRatio = RESERVE_RATIO;
        totalSupply_ = 1_000_000;
        balances[msg.sender] = totalSupply_;
        emit Transfer(address(0), msg.sender, totalSupply_);
    }

    function powerTest(uint256 baseN, uint256 baseD, uint32 expN, uint32 expD) public view returns (uint256, uint8) {
        return super.power(baseN, baseD, expN, expD);
    }

    function lnTest(uint256 numerator, uint256 denominator) public pure returns (uint256) {
        return super.ln(numerator, denominator);
    }

    function findPositionInMaxExpArrayTest(uint256 x) public view returns (uint8) {
        return super.findPositionInMaxExpArray(x);
    }

    function fixedExpTest(uint256 x, uint8 precision) public pure returns (uint256) {
        return super.fixedExp(x, precision);
    }

    function floorLog2Test(uint256 n) public pure returns (uint8) {
        return super.floorLog2(n);
    }
}
