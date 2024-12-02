// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../../src/Power.sol";

contract PowerMock is Power {
    constructor() {}

    function powerTest(uint256 _baseN, uint256 _baseD, uint32 _expN, uint32 _expD)
        public
        view
        returns (uint256, uint8)
    {
        return power(_baseN, _baseD, _expN, _expD);
    }

    function lnTest(uint256 _numerator, uint256 _denominator) public pure returns (uint256) {
        return ln(_numerator, _denominator);
    }

    function findPositionInMaxExpArrayTest(uint256 _x) public view returns (uint8) {
        return findPositionInMaxExpArray(_x);
    }

    function fixedExpTest(uint256 _x, uint8 _precision) public pure returns (uint256) {
        return fixedExp(_x, _precision);
    }

    function floorLog2Test(uint256 _n) public pure returns (uint8) {
        return floorLog2(_n);
    }
}
