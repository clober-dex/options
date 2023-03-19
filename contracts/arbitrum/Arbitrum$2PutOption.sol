// SPDX-License-Identifier: -
// License: https://license.clober.io/LICENSE.pdf

pragma solidity ^0.8.0;

import "../PutOptionToken.sol";

contract Arbitrum$2PutOption is PutOptionToken {
    constructor(
        address underlyingToken,
        address quoteToken,
        uint256 expiresAt
    )
        PutOptionToken(
            underlyingToken,
            quoteToken,
            2 * 10**18,
            expiresAt,
            1000, // 0.1%
            "Arbitrum $2 Put Options",
            "ARB$2PUT"
        )
    {}
}
