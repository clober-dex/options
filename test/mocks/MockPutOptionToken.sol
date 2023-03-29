// SPDX-License-Identifier: -
// License: https://license.clober.io/LICENSE.pdf

pragma solidity ^0.8.0;

import "../../contracts/PutOptionToken.sol";

contract MockPutOptionToken is PutOptionToken {
    constructor(
        address underlyingToken,
        address quoteToken,
        uint256 strikePrice,
        uint256 expiresAt,
        uint256 exerciseFee
    ) PutOptionToken(underlyingToken, quoteToken, strikePrice, expiresAt, exerciseFee, "Mock Put Option", "M-P") {}
}
