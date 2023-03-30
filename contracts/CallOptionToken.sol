// SPDX-License-Identifier: -
// License: https://license.clober.io/LICENSE.pdf

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/CloberOptionToken.sol";
import "./library/Math.sol";

contract CallOptionToken is ERC20, CloberOptionToken, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    uint256 private constant _FEE_PRECISION = 10**6;

    uint8 private immutable _decimals;
    IERC20 private immutable _quoteToken;
    IERC20 private immutable _underlyingToken;
    uint256 private immutable _precisionComplement; // 10**(18 + underlying - quote)

    // Write => timestamp <= expiresAt
    // Cancel => timestamp <= expiresAt
    // Exercise => timestamp <= expiresAt
    // Redeem => expiresAt > timestamp
    uint256 public immutable expiresAt;
    uint256 public immutable exerciseFee;
    uint256 public immutable strikePrice;

    mapping(address => uint256) public collateral;
    uint256 public exercisedAmount;
    uint256 public exerciseFeeBalance; // underlying

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
        _precisionComplement =
            10**(18 - IERC20Metadata(quoteToken_).decimals() + IERC20Metadata(underlyingToken_).decimals());

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

    function write(uint256 optionAmount) external nonReentrant {
        require(block.timestamp <= expiresAt, "OPTION_EXPIRED");
        require(optionAmount > 0, "INVALID_AMOUNT");

        uint256 collateralAmount = optionAmount;

        _underlyingToken.safeTransferFrom(msg.sender, address(this), collateralAmount);
        collateral[msg.sender] += collateralAmount;

        _mint(msg.sender, optionAmount);

        emit Write(msg.sender, optionAmount);
    }

    function cancel(uint256 optionAmount) external nonReentrant {
        require(block.timestamp <= expiresAt, "OPTION_EXPIRED");
        require(optionAmount > 0, "INVALID_AMOUNT");

        uint256 collateralAmount = optionAmount;

        collateral[msg.sender] -= collateralAmount;
        _burn(msg.sender, optionAmount);

        _underlyingToken.safeTransfer(msg.sender, collateralAmount);

        emit Cancel(msg.sender, optionAmount);
    }

    function exercise(uint256 optionAmount) external nonReentrant {
        require(block.timestamp <= expiresAt, "OPTION_EXPIRED");
        require(optionAmount > 0, "INVALID_AMOUNT");

        uint256 collateralAmount = optionAmount;

        _quoteToken.safeTransferFrom(
            msg.sender,
            address(this),
            Math.ceilDiv(optionAmount * strikePrice, _precisionComplement)
        );

        _burn(msg.sender, optionAmount);

        uint256 feeAmount = Math.ceilDiv(collateralAmount * exerciseFee, _FEE_PRECISION);
        exerciseFeeBalance += feeAmount;

        _underlyingToken.safeTransfer(msg.sender, collateralAmount - feeAmount);

        exercisedAmount += optionAmount;

        emit Exercise(msg.sender, optionAmount);
    }

    function _claim(address writer) internal nonReentrant {
        require(block.timestamp > expiresAt, "OPTION_NOT_EXPIRED");
        uint256 expiredAmount = totalSupply();
        uint256 totalWrittenAmount = expiredAmount + exercisedAmount;

        uint256 collateralAmount = collateral[writer];
        uint256 amount = (collateralAmount * strikePrice) / _precisionComplement;

        uint256 claimableQuoteAmount = (amount * exercisedAmount) / totalWrittenAmount;
        uint256 claimableUnderlyingAmount = (collateralAmount * expiredAmount) / totalWrittenAmount;

        collateral[writer] = 0;
        _quoteToken.transfer(writer, claimableQuoteAmount);
        _underlyingToken.transfer(writer, claimableUnderlyingAmount);

        emit Claim(writer, amount);
    }

    function claim() external {
        _claim(msg.sender);
    }

    function claim(address writer) external {
        _claim(writer);
    }

    function collectFee() external onlyOwner nonReentrant {
        _underlyingToken.transfer(msg.sender, exerciseFeeBalance);

        emit CollectFee(msg.sender, exerciseFeeBalance);
        exerciseFeeBalance = 0;
    }
}
