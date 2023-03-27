// SPDX-License-Identifier: -
// License: https://license.clober.io/LICENSE.pdf

pragma solidity ^0.8.0;

library Constants {
    address constant WRITER1 = address(1);
    address constant WRITER2 = address(2);
    address constant WRITER3 = address(3);
    address constant EXERCISER = address(4);
    uint256 constant FEE = 1000; // 0.01%
    uint256 constant FEE_PRECISION = 10**6;
}
