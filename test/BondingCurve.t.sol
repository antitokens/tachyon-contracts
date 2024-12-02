// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../test/helpers/BondingCurveMock.sol";

contract BondingCurveTest is Test {
    BondingCurveMock instance;
    uint256 constant decimals = 18;
    uint256 constant startSupply = 10 * 1e18; // 10 tokens
    uint256 constant startPoolBalance = 1 * 1e14; // 0.0001 ETH
    uint32 constant reserveRatio = uint32((1e6 * 1) / 3); // 1/3 in ppm
    address deployer = address(0x1);

    function setUp() public {
        vm.deal(deployer, 10 ether);
        vm.startPrank(deployer);

        instance = new BondingCurveMock{value: startPoolBalance}(startSupply, reserveRatio);

        vm.stopPrank();
    }

    function getRequestParams(uint256 amount)
        internal
        view
        returns (uint256 totalSupply, uint256 poolBalance, uint32 solRatio, uint256 price)
    {
        totalSupply = instance.totalSupply();
        poolBalance = instance.poolBalance();

        price = (poolBalance * ((1 + amount / totalSupply) ** (1e18 / reserveRatio) - 1)) / 1e18;

        solRatio = reserveRatio;
    }

    function testInitialisation() public {
        (uint256 totalSupply, uint256 poolBalance,,) = getRequestParams(0);

        uint256 contractBalance = address(instance).balance;
        uint256 ownerBalance = instance.balanceOf(deployer);

        assertEq(totalSupply, ownerBalance, "Initial tokens should go to owner");
        assertEq(startPoolBalance, contractBalance, "Contract should hold correct ETH");
        assertEq(startPoolBalance, poolBalance, "Pool balance should be correct");
    }

    function testEstimatePrice() public {
        uint256 amount = 13 * (10 ** decimals);
        (, uint256 poolBalance, uint32 solRatio, uint256 price) = getRequestParams(amount);

        uint256 estimate = instance.calculatePurchaseReturn(instance.totalSupply(), poolBalance, solRatio, price);

        assertApproxEqAbs(estimate, amount, 1e3, "Estimate should be accurate");
    }

    function testBuyTokens() public {
        uint256 amount = 8 * (10 ** decimals);

        uint256 startBalance = instance.balanceOf(deployer);
        (,,, uint256 price) = getRequestParams(amount);

        vm.prank(deployer);
        instance.buy{value: price}();

        uint256 endBalance = instance.balanceOf(deployer);
        uint256 amountBought = endBalance - startBalance;

        assertApproxEqAbs(amountBought, amount, 1e3, "Able to buy tokens correctly");
    }

    function testCannotBuyWithZeroETH() public {
        vm.expectRevert("VALUE <= 0");
        vm.prank(deployer);
        instance.buy{value: 0}();
    }

    function testCannotSellMoreThanOwned() public {
        uint256 balance = instance.balanceOf(deployer);
        vm.expectRevert("LOW_BALANCE_OR_BAD_INPUT");

        vm.prank(deployer);
        instance.sell(balance + 1);
    }

    function testSellTokens() public {
        uint256 sellAmount = instance.balanceOf(deployer) / 2;
        (uint256 totalSupply, uint256 poolBalance,,) = getRequestParams(sellAmount);

        uint256 saleReturn = instance.calculateSaleReturn(totalSupply, poolBalance, reserveRatio, sellAmount);

        uint256 contractBalanceBefore = address(instance).balance;

        vm.prank(deployer);
        instance.sell(sellAmount);

        uint256 contractBalanceAfter = address(instance).balance;
        uint256 change = contractBalanceBefore - contractBalanceAfter;

        assertEq(saleReturn, change, "Sale return should match contract balance change");
    }
}
