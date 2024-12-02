// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./BancorFormula.sol";

/**
 * @title Tachyon Bonding Curve on Base
 * @dev Bonding curve contract based on Bancor formula inspired by Bancor Protocol and simondlr
 * https://github.com/bancorprotocol/contracts
 * https://github.com/ConsenSys/curationmarkets/blob/master/CurationMarkets.sol
 */
contract BondingCurve is ERC20, BancorFormula {
    /**
     * @dev Available balance of reserve token in contract
     */
    uint256 public poolBalance;

    /**
     * @dev Reserve ratio, represented in ppm, 1-1000000
     */
    uint32 public reserveRatio;

    constructor(
        string memory _name,
        string memory _symbol,
        address _devAccount
    ) ERC20(_name, _symbol) BancorFormula(_devAccount) {}

    // Receive function for receiving Ether and routing it to buy tokens
    receive() external payable {
        buy();
    }

    /**
     * @dev Buy tokens
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
     * @param sellAmount Amount of tokens to withdraw
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

        (bool success, ) = msg.sender.call{value: ethAmount}(""); // Using call instead of transfer for sending Ether
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
