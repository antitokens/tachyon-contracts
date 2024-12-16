// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./BancorFormula.sol";

contract BondingCurve is ERC20, BancorFormula, ReentrancyGuard, Pausable, Ownable {
    using Address for address payable;

    uint256 public poolBalance;
    uint32 public immutable reserveRatio;

    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 10 ** 18;
    uint256 public constant MIN_PURCHASE = 0.01 ether;

    error InvalidReserveRatio();
    error InsufficientValue();
    error MaxSupplyExceeded();
    error SlippageProtectionFailed();
    error InvalidSellAmount();
    error InsufficientBalance();
    error EtherTransferFailed();

    event LogMint(address indexed buyer, uint256 amountMinted, uint256 cost, uint256 newSupply, uint256 newPoolBalance);
    event LogWithdraw(
        address indexed seller, uint256 amountWithdrawn, uint256 reward, uint256 newSupply, uint256 newPoolBalance
    );

    event FeeCollected(address indexed devAccount, uint256 amount);

    constructor(string memory _name, string memory _symbol, uint32 _reserveRatio, address _devAccount)
        ERC20(_name, _symbol)
        BancorFormula(_devAccount)
        Ownable(msg.sender) // Initialize Ownable with deployer as owner
    {
        if (_reserveRatio == 0 || _reserveRatio > 1000000) {
            revert InvalidReserveRatio();
        }
        reserveRatio = _reserveRatio;
    }

    /**
     * @dev Calculate current token price in ETH
     * @return price Current token price in ETH
     */
    function getCurrentPrice() public view returns (uint256 price) {
        if (totalSupply() == 0 || poolBalance == 0) {
            return 1 ether; // Initial price of 1 ETH
        }
        return (poolBalance * 1 ether) / totalSupply();
    }

    /**
     * @dev Receive function automatically buys tokens
     * @notice Minimum purchase amount applies
     */
    receive() external payable {
        buy(0); // Default minTokens is 0
    }

    /**
     * @dev Buy tokens by sending Ether
     * @param minTokens Minimum tokens to receive (slippage protection)
     * @return success Whether the purchase was successful
     */
    function buy(uint256 minTokens) public payable nonReentrant whenNotPaused returns (bool) {
        if (msg.value < MIN_PURCHASE) {
            revert InsufficientValue();
        }

        // Apply fee to the deposit amount
        uint256 depositAmount = applyFee(msg.value);
        uint256 feeAmount = msg.value - depositAmount;

        uint256 tokensToMint = calculatePurchaseReturn(totalSupply(), poolBalance, reserveRatio, depositAmount);

        if (tokensToMint < minTokens) {
            revert SlippageProtectionFailed();
        }

        if (totalSupply() + tokensToMint > MAX_SUPPLY) {
            revert MaxSupplyExceeded();
        }

        // Transfer fee to dev account
        if (feeAmount > 0) {
            (bool feeSuccess,) = devAccount.call{value: feeAmount}("");
            if (feeSuccess) {
                emit FeeCollected(devAccount, feeAmount);
            }
            // Continue even if fee transfer fails
        }

        poolBalance += depositAmount;
        _mint(msg.sender, tokensToMint);

        emit LogMint(msg.sender, tokensToMint, msg.value, totalSupply(), poolBalance);

        return true;
    }

    /**
     * @dev Sell tokens for Ether
     * @param sellAmount Amount of tokens to sell
     * @param minEth Minimum Ether to receive (slippage protection)
     * @return success Whether the sale was successful
     */
    function sell(uint256 sellAmount, uint256 minEth) public nonReentrant whenNotPaused returns (bool) {
        if (sellAmount == 0) {
            revert InvalidSellAmount();
        }
        if (balanceOf(msg.sender) < sellAmount) {
            revert InsufficientBalance();
        }

        uint256 ethAmount = calculateSaleReturn(totalSupply(), poolBalance, reserveRatio, sellAmount);

        // Apply fee to the withdrawn amount
        uint256 withdrawAmount = applyFee(ethAmount);
        uint256 feeAmount = ethAmount - withdrawAmount;

        if (withdrawAmount < minEth) {
            revert SlippageProtectionFailed();
        }

        // Update state before transfer
        _burn(msg.sender, sellAmount);
        poolBalance -= ethAmount;

        // Transfer fee to dev account if applicable
        if (feeAmount > 0) {
            (bool feeSuccess,) = devAccount.call{value: feeAmount}("");
            if (feeSuccess) {
                emit FeeCollected(devAccount, feeAmount);
            }
            // Continue even if fee transfer fails
        }

        // Transfer ETH to seller
        (bool success,) = msg.sender.call{value: withdrawAmount}("");
        if (!success) {
            // Revert state if transfer fails
            _mint(msg.sender, sellAmount);
            poolBalance += ethAmount;
            revert EtherTransferFailed();
        }

        emit LogWithdraw(msg.sender, sellAmount, withdrawAmount, totalSupply(), poolBalance);

        return true;
    }

    /**
     * @dev Emergency stop for pausing the contract
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Resume the contract after pausing
     */
    function unpause() external onlyOwner {
        _unpause();
    }
}
