pragma solidity ^0.8.0;

import "../PutOption.sol";

contract Arbitrum$1PutOption is PutOption {
    constructor(
        uint256 strikePrice_
    ) PutOption(
        0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8,
        0x912CE59144191C1204E64559FE8253a0e49E6548,
        1,
        1679574903 + 24 * 60 * 60
    ) ERC20("Arbitrum Put Option at $1", "ARB$1PUT") {}
}
