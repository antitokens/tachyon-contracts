// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../test/helpers/BondingCurveMock.sol";

contract BondingCurveTest is Test {
    BondingCurveMock instance;
    uint256 constant decimals = 18;
    uint256 constant INITIAL_SUPPLY = 1000 * 10 ** 18; // 1000 tokens
    uint256 constant startPoolBalance = 1 * 10 ** 16; // 0.01 ETH
    uint32 constant reserveRatio = uint32(333333); // 1/3 in ppm
    address deployer = address(0x1);

    function setUp() public {
        vm.deal(deployer, 10 ether);
        vm.startPrank(deployer);

        instance = new BondingCurveMock{value: startPoolBalance}();

        // Initialize supply and pool balance
        instance.setInitialState(INITIAL_SUPPLY, startPoolBalance);

        vm.stopPrank();
    }

    function testInitialisation() public {
        assertEq(instance.totalSupply(), INITIAL_SUPPLY, "Initial supply should be correct");
        assertEq(instance.balanceOf(deployer), INITIAL_SUPPLY, "Initial tokens should go to owner");
        assertEq(address(instance).balance, startPoolBalance, "Contract should hold correct ETH");
        assertEq(instance.poolBalance(), startPoolBalance, "Pool balance should be correct");
    }

    function testEstimatePrice() public {
        // Calculate the actual ETH needed for purchase
        uint256 ethAmount = 0.02 ether; // Ensure minimum purchase amount

        uint256 estimate =
            instance.calculatePurchaseReturn(instance.totalSupply(), instance.poolBalance(), reserveRatio, ethAmount);

        assertTrue(estimate > 0, "Estimate should be greater than 0");
    }

    function testBuyTokens() public {
        uint256 purchaseAmount = 0.02 ether; // Ensure above MIN_PURCHASE

        uint256 startBalance = instance.balanceOf(deployer);

        // Calculate expected tokens
        uint256 expectedTokens = instance.calculatePurchaseReturn(
            instance.totalSupply(), instance.poolBalance(), reserveRatio, purchaseAmount
        );

        // Set minTokens to 99% of expected tokens (1% slippage)
        uint256 minTokens = (expectedTokens * 99) / 100;

        vm.prank(deployer);
        instance.buy{value: purchaseAmount}(minTokens);

        uint256 endBalance = instance.balanceOf(deployer);
        uint256 amountBought = endBalance - startBalance;

        assertGt(amountBought, 0, "Should receive tokens");
        assertApproxEqRel(amountBought, expectedTokens, 0.01e18, "Should receive expected amount within 1%");
    }

    function testCannotBuyWithZeroETH() public {
        vm.expectRevert(abi.encodeWithSignature("InsufficientValue()"));
        vm.prank(deployer);
        instance.buy{value: 0}(0);
    }

    function testSlippageProtectionOnBuy() public {
        uint256 purchaseAmount = 0.02 ether; // Ensure above MIN_PURCHASE

        // Calculate expected tokens
        uint256 expectedTokens = instance.calculatePurchaseReturn(
            instance.totalSupply(), instance.poolBalance(), reserveRatio, purchaseAmount
        );

        // Set minimum tokens higher than expected
        uint256 minTokens = expectedTokens * 2;

        vm.prank(deployer);
        vm.expectRevert(abi.encodeWithSignature("SlippageProtectionFailed()"));
        instance.buy{value: purchaseAmount}(minTokens);
    }

    function testCannotSellMoreThanOwned() public {
        uint256 balance = instance.balanceOf(deployer);
        vm.prank(deployer);
        vm.expectRevert(abi.encodeWithSignature("InsufficientBalance()"));
        instance.sell(balance + 1, 0);
    }

    function testSellTokens() public {
        uint256 sellAmount = instance.balanceOf(deployer) / 2;
        uint256 saleReturn =
            instance.calculateSaleReturn(instance.totalSupply(), instance.poolBalance(), reserveRatio, sellAmount);

        uint256 minEth = (saleReturn * 99) / 100;

        uint256 contractBalanceBefore = address(instance).balance;

        vm.prank(deployer);
        instance.sell(sellAmount, minEth);

        uint256 contractBalanceAfter = address(instance).balance;
        uint256 change = contractBalanceBefore - contractBalanceAfter;

        assertApproxEqRel(saleReturn, change, 0.01e18, "Sale return should match contract balance change");
    }

    function testSellZeroAmount() public {
        vm.prank(deployer);
        vm.expectRevert(abi.encodeWithSignature("InvalidSellAmount()"));
        instance.sell(0, 0);
    }
}
