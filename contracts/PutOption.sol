pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

// American Put Options
abstract contract PutOption is ERC20 {
    using SafeERC20 for IERC20;

    address public immutable quoteToken;
    address public immutable underlyingToken;
    uint256 public immutable strikePrice;
    uint256 public immutable expiresAt;
    mapping(address => uint256) _writtenQuoteBalance;

    constructor(address quoteToken_, address underlyingToken_, uint256 strikePrice_, uint256 expiresAt_) {
        quoteToken = quoteToken_;
        underlyingToken = underlyingToken_;
        strikePrice = strikePrice_;
        expiresAt = expiresAt_;
    }

    function write(address user, uint256 amount) external {
        IERC20(quoteToken).safeTransferFrom(msg.sender, address(this), amount * strikePrice);
        _mint(user, amount);
        _writtenQuoteBalance[user] += amount * strikePrice;
    }

    function strike(uint256 amount) external {
        require(block.timestamp < expiresAt, "The option has expired");
        IERC20(underlyingToken).safeTransferFrom(msg.sender, address(this), amount);
        _burn(msg.sender, amount);
        IERC20(quoteToken).safeTransferFrom(address(this), msg.sender, amount * strikePrice);
    }

    function repay(uint256 amount) external {
        _burn(msg.sender, amount);
        _writtenQuoteBalance[msg.sender] -= amount * strikePrice;
        IERC20(quoteToken).safeTransferFrom(address(this), msg.sender, amount * strikePrice);
    }

    function claimUnderlying() external {
        require(block.timestamp >= expiresAt, "The option has not expired yet");
        IERC20(quoteToken).safeTransferFrom(address(this), msg.sender, _writtenQuoteBalance[msg.sender]);
    }
}
