// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./BancorFormula.sol";

/**
 * @title Tachyon Bonding Curve on Base
 * @dev Bonding curve contract based on Bancor formula inspired by Bancor Protocol and simondlr
 * https://github.com/bancorprotocol/contracts
 * https://github.com/ConsenSys/curationmarkets/blob/master/CurationMarkets.sol
 */
contract BondingCurve is ERC20, BancorFormula, Ownable {
    /**
     * @dev Available balance of reserve token in contract
     */
    uint256 public poolBalance;

    /*
     * @dev Reserve ratio, represented in ppm, 1-1000000
     * 1/3 corresponds to y = multiple * x^2
     * 1/2 corresponds to y = multiple * x
     * 2/3 corresponds to y = multiple * x^1/2
     * Multiple depends on contract initialisation, specifically totalAmount and poolBalance parameters.
     * Might want to add an 'initialize' function to allow the owner to send ether to the contract
     * and mint a given amount of tokens.
     */
    uint32 public reserveRatio;

    // Receive function for receiving Ether and route it to buy tokens
    receive() external payable {
        buy();
    }

    /**
     * @dev Buy tokens
     * gas ~ 
     * TODO: implement maxAmount to help prevent miner front-running
     */
    function buy() public payable returns (bool) {
        require(msg.value > 0, "VALUE <= 0");

        uint256 tokensToMint = calculatePurchaseReturn(
            totalSupply(),
            poolBalance,
            reserveRatio,
            msg.value
        );
        _mint(msg.sender, tokensToMint); // Using ERC20's _mint function
        poolBalance += msg.value;

        emit LogMint(tokensToMint, msg.value);
        return true;
    }

    /**
     * @dev Sell tokens
     * gas ~ 
     * @param sellAmount Amount of tokens to withdraw
     * TODO: implement maxAmount to help prevent miner front-running
     */
    function sell(uint256 sellAmount) public returns (bool) {
        require(
            sellAmount > 0 && balanceOf(msg.sender) >= sellAmount,
            "LOW_BALANCE_OR_BAD_INPUT"
        );

        uint256 ethAmount = calculateSaleReturn(
            totalSupply(),
            poolBalance,
            reserveRatio,
            sellAmount
        );

        (bool success, ) = msg.sender.call{value: ethAmount}(""); // Use call instead of transfer for sending Ether
        require(success, "FAIL");

        poolBalance -= ethAmount;
        _burn(msg.sender, sellAmount); // Using ERC20's _burn function

        emit LogWithdraw(sellAmount, ethAmount);
        return true;
    }

    event LogMint(uint256 amountMinted, uint256 totalCost);
    event LogWithdraw(uint256 amountWithdrawn, uint256 reward);
    event LogBondingCurve(string logString, uint256 value);
}
