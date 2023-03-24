// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

interface CloberOptionToken {
    event Write(address indexed writer, uint256 amount);

    event Cancel(address indexed writer, uint256 amount);

    event Exercise(address indexed recipient, uint256 amount);

    event Claim(address indexed recipient, uint256 amount);

    event CollectFee(address indexed recipient, uint256 amount);

    function underlyingToken() external view returns (address);

    function quoteToken() external view returns (address);

    function collateral(address) external view returns (uint256);

    function strikePrice() external view returns (uint256);

    function exercisedAmount() external view returns (uint256);

    function expiresAt() external view returns (uint256);

    function exerciseFee() external view returns (uint256);

    function exerciseFeeBalance() external view returns (uint256);

    function write(uint256 amount) external;

    function cancel(uint256 amount) external;

    function exercise(uint256 amount) external;

    function claim() external;
}
