// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

library Math {
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256 ret) {
        require(b > 0, "DIVIDE_BY_ZERO");
        assembly {
            ret := add(div(a, b), gt(mod(a, b), 0))
        }
    }
}