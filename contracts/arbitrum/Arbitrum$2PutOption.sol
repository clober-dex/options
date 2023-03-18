// SPDX-License-Identifier: -
// License: https://license.clober.io/LICENSE.pdf

pragma solidity ^0.8.0;

import "../PutOptionToken.sol";

contract Arbitrum$2PutOption is PutOptionToken {
    constructor()
        PutOptionToken(
            0x912CE59144191C1204E64559FE8253a0e49E6548,
            0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8,
            2 * 10**6,
            1679574903 + 24 * 60 * 60,
            10000, // 1%
            "Arbitrum Put Option at $2",
            "ARB$2PUT"
        )
    {}
}
