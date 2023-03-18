// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

interface OptionToken {
    event Mint(address indexed minter, uint256 amount);

    event Repay(address indexed payer, uint256 amount);

    event Exercise(address indexed recipient, uint256 amount);

    event Redeem(address indexed recipient, uint256 amount);

    event CollectFee(address indexed recipient, uint256 amount);

    function underlyingToken() external view returns (address);

    function quoteToken() external view returns (address);

    function strikePrice() external view returns (uint256);

    function exercisedAmount() external view returns (uint256);

    function expiresAt() external view returns (uint256);

    function exerciseFee() external view returns (uint256);

    function exerciseFeeBalance() external view returns (uint256);

    function write(uint256 amount) external;

    function repay(uint256 amount) external;

    function exercise(uint256 amount) external;

    //    function flashExercise(uint256 amount, bytes calldata data) external;

    function redeem(uint256 amount) external;
}
