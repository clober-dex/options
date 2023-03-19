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
    uint256 private constant _FEE_PRECISION = 10**6;

    uint8 private immutable _decimals;
    IERC20 private immutable _quoteToken;
    IERC20 private immutable _underlyingToken;
    uint256 private immutable _quotePrecisionComplement; // 10**(18 - d)

    // Write => timestamp <= expiresAt
    // Cancel => timestamp <= expiresAt
    // Exercise => timestamp <= expiresAt
    // Redeem => expiresAt > timestamp
    uint256 public immutable expiresAt;
    uint256 public immutable exerciseFee; // bp
    uint256 public immutable strikePrice;

    mapping(address => uint256) public collateral;
    uint256 public exercisedAmount;
    uint256 public exerciseFeeBalance; // quote

    constructor(
        address underlyingToken_,
        address quoteToken_,
        uint256 strikePrice_,
        uint256 expiresAt_,
        uint256 exerciseFee_,
        string memory name_,
        string memory symbol_
    ) ERC20(name_, symbol_) {
        _underlyingToken = IERC20(underlyingToken_);
        _quoteToken = IERC20(quoteToken_);
        _quotePrecisionComplement = 10**(18 - IERC20Metadata(quoteToken_).decimals());

        _decimals = IERC20Metadata(underlyingToken_).decimals();

        strikePrice = strikePrice_;
        expiresAt = expiresAt_;
        exerciseFee = exerciseFee_;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function underlyingToken() external view returns (address) {
        return address(_underlyingToken);
    }

    function quoteToken() external view returns (address) {
        return address(_quoteToken);
    }

    function write(uint256 amount) external nonReentrant {
        require(block.timestamp <= expiresAt, "OPTION_EXPIRED");

        uint256 collateralAmount = (amount * strikePrice) / _PRECISION / _quotePrecisionComplement;
        amount = (collateralAmount * _PRECISION * _quotePrecisionComplement) / strikePrice;
        require(amount > 0, "INVALID_AMOUNT");

        _quoteToken.safeTransferFrom(msg.sender, address(this), collateralAmount);
        collateral[msg.sender] += collateralAmount;

        _mint(msg.sender, amount);

        emit Write(msg.sender, amount);
    }

    function cancel(uint256 amount) external nonReentrant {
        require(block.timestamp <= expiresAt, "OPTION_EXPIRED");

        uint256 collateralAmount = (amount * strikePrice) / _PRECISION / _quotePrecisionComplement;
        amount = (collateralAmount * _PRECISION * _quotePrecisionComplement) / strikePrice;
        require(amount > 0, "INVALID_AMOUNT");

        collateral[msg.sender] -= collateralAmount;
        _burn(msg.sender, amount);

        _quoteToken.transfer(msg.sender, collateralAmount);

        emit Cancel(msg.sender, amount);
    }

    function exercise(uint256 amount) external nonReentrant {
        require(block.timestamp <= expiresAt, "OPTION_EXPIRED");

        uint256 collateralAmount = (amount * strikePrice) / _PRECISION / _quotePrecisionComplement;
        amount = (collateralAmount * _PRECISION * _quotePrecisionComplement) / strikePrice;
        require(amount > 0, "INVALID_AMOUNT");

        _underlyingToken.safeTransferFrom(msg.sender, address(this), amount);
        _burn(msg.sender, amount);

        uint256 feeAmount = (collateralAmount * exerciseFee) / _FEE_PRECISION;
        exerciseFeeBalance += feeAmount;

        _quoteToken.transfer(msg.sender, collateralAmount - feeAmount);

        exercisedAmount += amount;

        emit Exercise(msg.sender, amount);
    }

    function claim() external nonReentrant {
        require(block.timestamp > expiresAt, "OPTION_NOT_EXPIRED");
        uint256 expiredAmount = totalSupply();
        uint256 totalWrittenAmount = expiredAmount + exercisedAmount;

        uint256 collateralAmount = collateral[msg.sender];
        uint256 amount = (collateralAmount * _PRECISION * _quotePrecisionComplement) / strikePrice;

        uint256 claimableQuoteAmount = (collateralAmount * expiredAmount) / totalWrittenAmount;
        uint256 claimableUnderlyingAmount = (amount * exercisedAmount) / totalWrittenAmount;

        collateral[msg.sender] = 0;
        _quoteToken.transfer(msg.sender, claimableQuoteAmount);
        _underlyingToken.transfer(msg.sender, claimableUnderlyingAmount);

        emit Claim(msg.sender, amount);
    }

    function collectFee() external onlyOwner nonReentrant {
        _underlyingToken.transfer(msg.sender, exerciseFeeBalance);
        exerciseFeeBalance = 0;

        emit CollectFee(msg.sender, exerciseFeeBalance);
    }
}
