// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

library Math {
    /**
     * @dev `b` has to be never zero
     */
    function divide(
        uint256 a,
        uint256 b,
        bool roundingUp
    ) internal pure returns (uint256 ret) {
        assembly {
            ret := add(div(a, b), and(gt(mod(a, b), 0), roundingUp))
        }
    }
}
