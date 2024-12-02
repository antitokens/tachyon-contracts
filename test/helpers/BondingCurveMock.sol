// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../../src/BondingCurve.sol";

contract BondingCurveMock is BondingCurve {
    uint32 constant RESERVE_RATIO = uint32(333333); // 1/3 in ppm (parts per million)
    uint256 public totalSupply_;
    mapping(address => uint256) public balances;

    constructor() payable BondingCurve("BondingCurveMock", "BCM", msg.sender) {
        reserveRatio = RESERVE_RATIO;
        totalSupply_ = 1_000_000;
        balances[msg.sender] = totalSupply_;
        emit Transfer(address(0), msg.sender, totalSupply_);
    }

    function powerTest(uint256 _baseN, uint256 _baseD, uint32 _expN, uint32 _expD)
        public
        view
        returns (uint256, uint8)
    {
        return super.power(_baseN, _baseD, _expN, _expD);
    }

    function lnTest(uint256 _numerator, uint256 _denominator) public pure returns (uint256) {
        return super.ln(_numerator, _denominator);
    }

    function findPositionInMaxExpArrayTest(uint256 _x) public view returns (uint8) {
        return super.findPositionInMaxExpArray(_x);
    }

    function fixedExpTest(uint256 _x, uint8 _precision) public pure returns (uint256) {
        return super.fixedExp(_x, _precision);
    }

    function floorLog2Test(uint256 _n) public pure returns (uint8) {
        return super.floorLog2(_n);
    }
}
