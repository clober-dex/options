// SPDX-License-Identifier: -
// License: https://license.clober.io/LICENSE.pdf

pragma solidity ^0.8.0;

import "../../contracts/CallOptionToken.sol";

contract MockCallOptionToken is CallOptionToken {
    constructor(
        address underlyingToken,
        address quoteToken,
        uint256 strikePrice,
        uint256 expiresAt,
        uint256 exerciseFee
    ) CallOptionToken(underlyingToken, quoteToken, strikePrice, expiresAt, exerciseFee, "Mock Call Option", "M-C") {}
}
