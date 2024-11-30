[![](https://raw.githubusercontent.com/antitokens/tachyon/main/.github/badge.svg?v=12345)](https://github.com/antitokens/tachyon/actions/workflows/test.yml)

# `Tachyon`

### `Cross-chain Derivative using $ANTI - $PRO`

## Setup

#### 1. [Install Foundry](https://getfoundry.sh/)
`curl -L https://foundry.paradigm.xyz | bash && source ~/.bashrc && foundryup`

#### 2. Install dependency
`forge install foundry-rs/forge-std --no-commit --no-git`

#### 3. Goerli Testnet
 `./test/goerli.sh`

## Specification

This specification uses DIA Protocol and ERC-20 at core, besides EIP-155.

### 1. Price Oracle (EIP-3688)

This specification uses EIP-3688 to input the `δ` between `$ANTI` and `$PRO` prices (`= abs($ANTI - $PRO)`) to the mint function.

```solidity
function resolve(bytes calldata name, bytes calldata data) external view returns(bytes memory result)
```

### 2. Tokenomics

Here’s a self-contained Solidity contract based on the Bancor bonding curve that includes:

**a)** **1% Fee**: The contract charges a **1% fee** on both **buy** and **sell** transactions.

**b)** **Delta Coefficient**: A **multiplier `δ`** is applied to both the **buy** and **sell** formulas to modify the price dynamics.

---

### 3. Full Contract: 

#### a. BANCOR CURVE
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Power.sol";

/**
 * @title Bancor Formula
 * @dev Modified Bancor formula for Solidity 0.8.x with built-in overflow checks.
 */
contract BancorFormula is Power {
    string public version = "0.1";
    uint32 private constant MAX_WEIGHT = 1000000;
    uint256 private constant FEE_PERCENTAGE = 100; // 1% = 1/10000 = 100ppm

    address public devAccount = address(0);  // Developer's account to collect fees

    /**
     * @dev Constructor to initialize the dev account
     * @param _devAccount The developer account address that will receive the fees
     */
    function newDev(address _devAccount) public {
      require(_devAccount != address(0), "INVALID_ADDRESS");
      devAccount = _devAccount;
    }

    /**
     * @dev Calculates the return for a given purchase.
     *
     * Formula: Return = _supply * ((1 + _depositAmount / _connectorBalance) ^ (_connectorWeight / 1000000) - 1)
     */
    function calculatePurchaseReturn(
        uint256 _supply,
        uint256 _connectorBalance,
        uint32 _connectorWeight,
        uint256 _depositAmount
    ) public view returns (uint256) {
        require(
            _supply > 0 && _connectorBalance > 0 && _connectorWeight > 0 && _connectorWeight <= MAX_WEIGHT,
            "INVALID_INPUT"
        );

        if (_depositAmount == 0) {
            return 0;
        }

        if (_connectorWeight == MAX_WEIGHT) {
            return (_supply * _depositAmount) / _connectorBalance;
        }

        uint256 result;
        uint8 precision;
        uint256 baseN = _depositAmount + _connectorBalance;
        (result, precision) = power(baseN, _connectorBalance, _connectorWeight, MAX_WEIGHT);
        uint256 temp = (_supply * result) >> uint256(precision);
        return temp - _supply;
    }

    /**
     * @dev Calculates the return for a given sale.
     *
     * Formula: Return = _connectorBalance * (1 - (1 - _sellAmount / _supply) ^ (1 / (_connectorWeight / 1000000)))
     */
    function calculateSaleReturn(
        uint256 _supply,
        uint256 _connectorBalance,
        uint32 _connectorWeight,
        uint256 _sellAmount
    ) public view returns (uint256) {
        require(
            _supply > 0 &&
                _connectorBalance > 0 &&
                _connectorWeight > 0 &&
                _connectorWeight <= MAX_WEIGHT &&
                _sellAmount <= _supply,
            "INVALID_INPUT"
        );

        if (_sellAmount == 0) {
            return 0;
        }

        if (_sellAmount == _supply) {
            return _connectorBalance;
        }

        if (_connectorWeight == MAX_WEIGHT) {
            return (_connectorBalance * _sellAmount) / _supply;
        }

        uint256 result;
        uint8 precision;
        uint256 baseD = _supply - _sellAmount;
        (result, precision) = power(_supply, baseD, MAX_WEIGHT, _connectorWeight);
        uint256 oldBalance = _connectorBalance * result;
        uint256 newBalance = _connectorBalance << uint256(precision);
        return (oldBalance - newBalance) / result;
    }

    // Helper to apply a fee to any amount
    function applyFee(uint256 _amount) internal pure returns (uint256) {
        return _amount.mul(10000 - FEE_PERCENTAGE).div(10000);
    }
}
```

#### b. INTERFACE:
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./BancorFormula.sol";

/**
 * @title BondingCurve
 * @dev Bonding curve contract based on the Bancor formula and adapted for EIP-1559
 */
contract BondingCurve is ERC20, BancorFormula, Ownable {
    uint256 public poolBalance;
    uint32 public reserveRatio;

    event LogMint(uint256 amountMinted, uint256 totalCost);
    event LogWithdraw(uint256 amountWithdrawn, uint256 reward);

    constructor(
        string memory name_,
        string memory symbol_,
        uint32 _reserveRatio,
        uint256 _baseFeeLimit
    ) ERC20(name_, symbol_) {
        require(_reserveRatio > 0 && _reserveRatio <= 1000000, "INVALID_RATIO");
        reserveRatio = _reserveRatio;
        baseFeeLimit = _baseFeeLimit;
    }

    /**
     * @dev Fallback function to buy tokens with Ether
     */
    receive() external payable {
        buy();
    }

    /**
     * @dev Buy tokens by sending Ether
     */
    function buy() public payable returns (bool) {
        require(msg.value > 0, "SEND_ETHER");

        uint256 tokensToMint = calculatePurchaseReturn(
            totalSupply(),
            poolBalance,
            reserveRatio,
            msg.value
        );

        // Apply 1% fee
        uint256 fee = tokensToMint.mul(FEE_PERCENT).div(100);
        tokensToMint -= fee;

        _mint(msg.sender, tokensToMint);
        poolBalance += msg.value;

        emit LogMint(tokensToMint, msg.value);
        return true;
    }

    /**
     * @dev Sell tokens for Ether
     * @param sellAmount Amount of tokens to sell
     */
    function sell(uint256 sellAmount) public returns (bool) {
        require(sellAmount > 0 && balanceOf(msg.sender) >= sellAmount, "INVALID_AMOUNT");

        uint256 ethAmount = calculateSaleReturn(
            totalSupply(),
            poolBalance,
            reserveRatio,
            sellAmount
        );

        // Apply 1% fee
        uint256 fee = ethAmount.mul(FEE_PERCENT).div(100);
        ethAmount -= fee;
        msg.sender.transfer(ethAmount);
        devAccount.transfer(fee);  // Transfer fee to developer

        _burn(msg.sender, sellAmount);
        poolBalance -= ethAmount;

        payable(msg.sender).transfer(ethAmount);

        emit LogWithdraw(sellAmount, ethAmount);
        return true;
    }

}
```

---

### Key Changes:

1. **1% Fee**:
   - The **`FEE_PERCENTAGE`** is set to **100** (representing 100 parts per million, or 1%). This fee is applied to both buy and sell transactions by multiplying the deposit/sell amount with `(10000 - FEE_PERCENTAGE) / 10000`.
   
2. **Delta Coefficient (`δ`)**:
   - The **`δ`** multiplier allows adjusting the return on both buy and sell formulas. It is a parameter that scales the output based on your preference.
   - You can change its value using the `setDelta` function.

---

### 4. Key Formula Changes from Bancor:

1. **Buy Formula** (with `δ` and fee applied):

    `RETURN = (1 - FEE) × SUPPLY × ((1 + DEPOSIT / POOL)^(WEIGHT / MAX_WEIGHT) - 1) × δ 
`

1. **Sell Formula** (with `δ` and fee applied):

    `RETURN = (1 - FEE) × POOL × (1 - (1 - SELL / SUPPLY)^(MAX_WEIGHT / WEIGHT)) × δ 
`


---

## Summary

- **Fees**: The contract charges **1%** on both buy and sell transactions.
- **Delta**: The **`δ`** multiplier allows flexible tuning of the bonding curve returns.
