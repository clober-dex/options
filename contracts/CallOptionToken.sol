// SPDX-License-Identifier: -
// License: https://license.clober.io/LICENSE.pdf

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/CloberOptionToken.sol";

contract CallOptionToken is ERC20, CloberOptionToken, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    uint256 private constant _FEE_PRECISION = 10**6;

    uint8 private immutable _decimals;
    IERC20 private immutable _quoteToken;
    IERC20 private immutable _underlyingToken;
    uint256 private immutable _quotePrecisionComplement; // 10**(36 - d)

    // Write => timestamp <= expiresAt
    // Cancel => timestamp <= expiresAt
    // Exercise => timestamp <= expiresAt
    // Redeem => expiresAt > timestamp
    uint256 public immutable expiresAt;
    uint256 public immutable exerciseFee;
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
        _quotePrecisionComplement = 10**(36 - IERC20Metadata(quoteToken_).decimals());

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
        require(amount > 0, "INVALID_AMOUNT");

        _underlyingToken.safeTransferFrom(msg.sender, address(this), amount);
        collateral[msg.sender] += amount;

        _mint(msg.sender, amount);

        emit Write(msg.sender, amount);
    }

    function cancel(uint256 amount) external nonReentrant {
        require(block.timestamp <= expiresAt, "OPTION_EXPIRED");
        require(amount > 0, "INVALID_AMOUNT");

        collateral[msg.sender] -= amount;
        _burn(msg.sender, amount);

        _underlyingToken.transfer(msg.sender, amount);

        emit Cancel(msg.sender, amount);
    }

    function exercise(uint256 amount) external nonReentrant {
        require(block.timestamp <= expiresAt, "OPTION_EXPIRED");
        require(amount > 0, "INVALID_AMOUNT");

        _underlyingToken.safeTransferFrom(msg.sender, address(this), amount);
        _burn(msg.sender, amount);

        uint256 quoteAmount = (amount * strikePrice) / _quotePrecisionComplement;
        uint256 feeAmount = (quoteAmount * exerciseFee) / _FEE_PRECISION;
        exerciseFeeBalance += feeAmount;

        _quoteToken.transfer(msg.sender, quoteAmount - feeAmount);

        exercisedAmount += amount;

        emit Exercise(msg.sender, amount);
    }

    function _claim(address writer) internal nonReentrant {
        require(block.timestamp > expiresAt, "OPTION_NOT_EXPIRED");
        uint256 expiredAmount = totalSupply();
        uint256 totalWrittenAmount = expiredAmount + exercisedAmount;

        uint256 collateralAmount = collateral[writer];
        require(collateralAmount > 0, "INVALID_AMOUNT");

        uint256 claimableUnderlyingAmount = (collateralAmount * expiredAmount) / totalWrittenAmount;
        uint256 claimableQuoteAmount = (collateralAmount * exercisedAmount * strikePrice) /
            (totalWrittenAmount * _quotePrecisionComplement);

        collateral[writer] = 0;
        _quoteToken.transfer(writer, claimableQuoteAmount);
        _underlyingToken.transfer(writer, claimableUnderlyingAmount);

        emit Claim(writer, collateralAmount);
    }

    function claim() external {
        _claim(msg.sender);
    }

    function claim(address writer) external {
        _claim(writer);
    }

    function collectFee() external onlyOwner nonReentrant {
        _quoteToken.transfer(msg.sender, exerciseFeeBalance);
        exerciseFeeBalance = 0;

        emit CollectFee(msg.sender, exerciseFeeBalance);
    }
}
