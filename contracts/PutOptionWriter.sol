pragma solidity ^0.8.0;

import "./PutOption.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract PutOptionWriter {
    using SafeERC20 for IERC20;

    function write(PutOption putOption, address user, uint256 amount) external {
        IERC20(putOption.quoteToken()).safeTransferFrom(msg.sender, address(this), amount * putOption.strikePrice());
        putOption.write(user, amount);
    }
}
