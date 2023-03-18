// SPDX-License-Identifier: -
// License: https://license.clober.io/LICENSE.pdf

pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../../../contracts/mock/MockUnderlyingToken.sol";
import "../../../contracts/mock/MockQuoteToken.sol";
import "../../../contracts/mock/MockPutOption.sol";

contract PutOptionsUnitTest is Test {
    MockPutOption putOptions;
    MockQuoteToken quoteToken;
    MockUnderlyingToken underlyingToken;

    function setUp() public {
        quoteToken = new MockQuoteToken();
        underlyingToken = new MockUnderlyingToken();

        putOptions = new MockPutOption(
            address(quoteToken),
            address(underlyingToken),
            10**12,
            1679574903 + 24 * 60 * 60,
            10000 // 1%
        );
    }

    function testERC20() public {
        assertEq(putOptions.name(), "Mock Put Option", "EXACT_NAME");
        assertEq(putOptions.symbol(), "M-P", "EXACT_STMBOL");
        assertEq(putOptions.decimals(), 18, "EXACT_DECIMALS");
    }
}
