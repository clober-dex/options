// SPDX-License-Identifier: -
// License: https://license.clober.io/LICENSE.pdf

pragma solidity ^0.8.0;

import "./MockERC20.sol";

contract MockUnderlyingToken is MockERC20("Fake ARB", "fARB", 12) {}
