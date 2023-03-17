pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

// American Put Options
abstract contract PutOption is ERC20 {
    using SafeERC20 for IERC20;

    address immutable _quoteToken;
    address immutable _underlyingToken;
    uint256 immutable _strikePrice;
    uint256 immutable _expiresAt;
    mapping(address => uint256) _writtenQuoteBalance;

    constructor(address quoteToken_, address underlyingToken_, uint256 strikePrice_, uint256 expiresAt_) {
        _quoteToken = quoteToken_;
        _underlyingToken = underlyingToken_;
        _strikePrice = strikePrice_;
        _expiresAt = expiresAt_;
    }

    function write(address user, uint256 amount) external {
        IERC20(_quoteToken).safeTransferFrom(msg.sender, address(this), amount * _strikePrice);
        _mint(user, amount);
        _writtenQuoteBalance[user] += amount * _strikePrice;
    }

    function strike(uint256 amount) external {
        require(block.timestamp < _expiresAt, "The option has expired");
        IERC20(_underlyingToken).safeTransferFrom(msg.sender, address(this), amount);
        _burn(msg.sender, amount);
        IERC20(_quoteToken).safeTransferFrom(address(this), msg.sender, amount * _strikePrice);
    }

    function repay(uint256 amount) external {
        _burn(msg.sender, amount);
        _writtenQuoteBalance[msg.sender] -= amount * _strikePrice;
        IERC20(_quoteToken).safeTransferFrom(address(this), msg.sender, amount * _strikePrice);
    }

    function claimUnderlying() external {
        require(block.timestamp >= _expiresAt, "The option has not expired yet");
        IERC20(_quoteToken).safeTransferFrom(address(this), msg.sender, _writtenQuoteBalance[msg.sender]);
    }
}
