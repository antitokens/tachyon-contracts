// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Power.sol";
import "./helpers/PowerFormulaConstants.sol";

contract PowerTest is Test {
    Power formula;

    uint256 constant ILLEGAL_VALUE = 2**256;
    uint256 constant MAX_NUMERATOR = 2**(256 - PowerFormulaConstants.MAX_PRECISION) - 1;
    uint256 constant MIN_DENOMINATOR = 1;
    uint256 constant MAX_EXPONENT = 1_000_000;

    function setUp() public {
        formula = new Power();
    }

    function testPower(uint256 percent) public {
        vm.assume(percent >= 1 && percent <= 100);

        uint256 baseN = MAX_NUMERATOR;
        uint256 baseD = MAX_NUMERATOR - 1;
        uint256 expN = (MAX_EXPONENT * percent) / 100;
        uint256 expD = MAX_EXPONENT;

        bool expectedPass = percent <= 100;

        if (expectedPass) {
            formula.powerTest(baseN, baseD, expN, expD);
        } else {
            vm.expectRevert();
            formula.powerTest(baseN, baseD, expN, expD);
        }
    }

    function testLn(uint256 caseIndex) public {
        vm.assume(caseIndex < 3);

        struct TestCase {
            uint256 numerator;
            uint256 denominator;
            bool assertion;
        }

        TestCase[3] memory cases = [
            TestCase(MAX_NUMERATOR, MAX_NUMERATOR - 1, true),
            TestCase(MAX_NUMERATOR, MIN_DENOMINATOR, true),
            TestCase(MAX_NUMERATOR + 1, MIN_DENOMINATOR, false)
        ];

        uint256 numerator = cases[caseIndex].numerator;
        uint256 denominator = cases[caseIndex].denominator;
        bool assertion = cases[caseIndex].assertion;

        if (assertion) {
            uint256 result = formula.lnTest(numerator, denominator);
            assertTrue(result * MAX_EXPONENT < ILLEGAL_VALUE, "Output too large");
        } else {
            vm.expectRevert();
            formula.lnTest(numerator, denominator);
        }
    }

    function testFixedExp(uint256 precision) public {
        vm.assume(precision >= PowerFormulaConstants.MIN_PRECISION && precision <= PowerFormulaConstants.MAX_PRECISION);

        uint256 maxExp = PowerFormulaConstants.maxExpArray(precision);
        uint256 maxVal = PowerFormulaConstants.maxValArray(precision);

        uint256 result = formula.fixedExpTest(maxExp, precision);
        assertEq(result, maxVal, "Output mismatch");
    }

    function testFloorLog2(uint256 n) public {
        vm.assume(n >= 1 && n <= 255);

        uint256 input = 2**n;
        uint256 expected = n;

        uint256 result = formula.floorLog2Test(input);
        assertEq(result, expected, "Output mismatch");
    }
}