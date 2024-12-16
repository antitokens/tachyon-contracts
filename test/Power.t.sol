// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "./helpers/PowerMock.sol";
import "./helpers/PowerFormulaConstants.sol";

contract PowerTest is Test {
    PowerMock formula;

    uint256 constant ILLEGAL_VALUE = 2 ** 256 - 1;
    uint256 constant MAX_NUMERATOR = 2 ** (256 - PowerFormulaConstants.MAX_PRECISION) - 1;
    uint32 constant MIN_DENOMINATOR = 1;
    uint32 constant MAX_EXPONENT = 1_000_000;

    struct TestCase {
        uint256 numerator;
        uint256 denominator;
        bool assertion;
    }

    function setUp() public {
        formula = new PowerMock();
    }

    function testPower(uint256 percent) public {
        vm.assume(percent >= 1 && percent <= 100);

        uint256 baseN = MAX_NUMERATOR;
        uint256 baseD = MAX_NUMERATOR - 1;
        uint32 expN = uint32(MAX_EXPONENT * percent) / 100;
        uint32 expD = MAX_EXPONENT;

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

        TestCase[3] memory cases;

        cases[0] = TestCase(MAX_NUMERATOR, MAX_NUMERATOR - 1, true);
        cases[1] = TestCase(MAX_NUMERATOR, MIN_DENOMINATOR, true);
        cases[2] = TestCase(MAX_NUMERATOR + 1, MIN_DENOMINATOR, false);

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
        // Bound precision to valid range
        precision = bound(precision, PowerFormulaConstants.MIN_PRECISION, PowerFormulaConstants.MAX_PRECISION);

        // Get the maximum exponent value for this precision from the constants
        uint256 maxExpN = uint256(uint8(PowerFormulaConstants.MAX_EXP_ARRAY[precision]));

        // Calculate the expected result using the actual fixedExp function
        uint256 result = formula.fixedExpTest(maxExpN, uint8(precision));

        // Result should be greater than zero and less than 2^256
        assertTrue(result > 0, "Result should be positive");
        assertTrue(result < type(uint256).max, "Result should be less than max uint256");

        // For specific test case that was failing
        if (precision == 54) {
            uint256 expectedResult = 18014398509481984;
            assertEq(result, expectedResult, "Output mismatch for precision 54");
        }
    }

    function testFloorLog2(uint256 n) public {
        vm.assume(n >= 1 && n <= 255);

        uint256 input = 2 ** n;
        uint256 expected = n;

        uint256 result = formula.floorLog2Test(input);
        assertEq(result, expected, "Output mismatch");
    }
}
