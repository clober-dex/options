// SPDX-License-Identifier: -
// License: https://license.clober.io/LICENSE.pdf

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/OptionToken.sol";

contract PutOptionToken is ERC20, OptionToken, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    uint256 private constant _PRECISION = 10**18;

    uint256 private immutable _UNDERLYING_PRECISION;
    IERC20 private immutable _underlyingToken;
    uint256 private immutable _QUOTE_PRECISION;
    IERC20 private immutable _quoteToken;

    mapping(address => uint256) private _collateral;
    uint256 public exercisedAmount;

    uint256 public immutable strikePrice;

    // Mint => timestamp <= expiresAt
    // Repay => timestamp <= expiresAt
    // Exercise => timestamp <= expiresAt
    // Redeem => expiresAt > timestamp
    uint256 public immutable expiresAt;

    uint256 private constant _FEE_PRECISION = 10**6;
    uint256 public immutable exerciseFee;

    uint256 private constant _FEE_BALANCE_PRECISION = 10**18;
    uint256 public exerciseFeeBalance; // underlyingToken

    constructor(
        address quoteToken_,
        address underlyingToken_,
        uint256 strikePrice_,
        uint256 expiresAt_,
        uint256 exerciseFee_,
        string memory name_,
        string memory symbol_
    ) ERC20(name_, symbol_) {
        _underlyingToken = IERC20(underlyingToken_);
        _UNDERLYING_PRECISION = 10**IERC20Metadata(underlyingToken_).decimals();
        _quoteToken = IERC20(quoteToken_);
        _QUOTE_PRECISION = 10**IERC20Metadata(quoteToken_).decimals();

        strikePrice = strikePrice_;
        expiresAt = expiresAt_;
        exerciseFee = exerciseFee_;
    }

    function underlyingToken() external view returns (address) {
        return address(_underlyingToken);
    }

    function quoteToken() external view returns (address) {
        return address(_quoteToken);
    }

    function mint(uint256 amount) external nonReentrant {
        require(block.timestamp <= expiresAt, "OPTION_EXPIRED");

        uint256 collateralAmount = (amount * strikePrice) / _PRECISION;
        _underlyingToken.safeTransferFrom(msg.sender, address(this), collateralAmount);

        _collateral[msg.sender] += collateralAmount;
        _mint(msg.sender, amount);
        emit Mint(msg.sender, amount);
    }

    function repay(uint256 amount) external nonReentrant {
        uint256 collateralAmount = (amount * strikePrice) / _PRECISION;
        _underlyingToken.transfer(msg.sender, collateralAmount);
        _collateral[msg.sender] -= collateralAmount;
        _burn(msg.sender, amount);
        emit Repay(msg.sender, amount);
    }

    function _exercise(uint256 amount) private {
        require(block.timestamp <= expiresAt, "OPTION_EXPIRED");

        _burn(msg.sender, amount);
        uint256 collateralAmount = (amount * strikePrice) / _PRECISION;

        // fee by underlying
        uint256 feeAmount = (collateralAmount * exerciseFee) / _FEE_PRECISION;
        exerciseFeeBalance += feeAmount;

        _underlyingToken.transfer(msg.sender, collateralAmount);
        exercisedAmount += amount;
        emit Exercise(msg.sender, amount);
    }

    function exercise(uint256 amount) external nonReentrant {
        _quoteToken.safeTransferFrom(msg.sender, address(this), (amount * _QUOTE_PRECISION) / _PRECISION);
        _exercise(amount);
    }

    function redeem(uint256 amount) external nonReentrant {
        require(block.timestamp > expiresAt, "OPTION_NOT_EXPIRED");
        uint256 expiredAmount = totalSupply();
        uint256 redeemableUnderlyingAmount = (amount * expiredAmount * strikePrice) /
            _PRECISION /
            (expiredAmount + exercisedAmount);
        uint256 redeemableQuoteAmount = (amount * exercisedAmount) / _PRECISION / (expiredAmount + exercisedAmount);

        _collateral[msg.sender] -= (amount * strikePrice) / _PRECISION;
        _underlyingToken.transfer(msg.sender, redeemableUnderlyingAmount);
        _quoteToken.transfer(msg.sender, redeemableQuoteAmount);

        emit Redeem(msg.sender, amount);
    }

    function collectFee() external onlyOwner nonReentrant {
        _quoteToken.transfer(msg.sender, exerciseFeeBalance - 1);
        exerciseFeeBalance = 1;

        emit CollectFee(msg.sender, exerciseFeeBalance - 1);
    }
}
