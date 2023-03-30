// SPDX-License-Identifier: -
// License: https://license.clober.io/LICENSE.pdf

pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "../Constants.sol";
import "../../../../contracts/CallOptionToken.sol";
import "../../../mocks/MockCallOptionToken.sol";
import "../../../mocks/MockQuoteToken.sol";
import "../../../mocks/MockUnderlyingToken.sol";
import "./SetUp.sol";

contract CallOptionWriteUnitTest is Test {
    event Write(address indexed writer, uint256 amount);

    CallOptionToken optionToken;

    MockQuoteToken quoteToken;
    MockUnderlyingToken underlyingToken;

    function setUp() public {
        (quoteToken, underlyingToken, optionToken) = (new CallOptionTokenUnitTestSetUp()).run(
            37 * 10**12, // $0.000037
            10000 // 1%
        );
    }

    function _write(
        address user,
        uint256 optionAmount,
        uint256 expectedUnderlyingAmount
    ) private {
        uint256 beforeOptionBalance = optionToken.balanceOf(user);
        uint256 beforeUnderlyingBalance = underlyingToken.balanceOf(user);
        uint256 beforeCollateralBalance = optionToken.collateral(user);

        vm.expectEmit(true, false, false, true);
        emit Write(user, optionAmount);
        vm.prank(user);
        optionToken.write(optionAmount);

        assertEq(optionToken.balanceOf(user), beforeOptionBalance + optionAmount, "WRITE_OPTION_BALANCE");
        assertEq(
            underlyingToken.balanceOf(user),
            beforeUnderlyingBalance - expectedUnderlyingAmount,
            "WRITE_QUOTE_BALANCE"
        );
        assertEq(
            optionToken.collateral(user),
            beforeCollateralBalance + expectedUnderlyingAmount,
            "WRITE_COLLATERAL_BALANCE"
        );
    }

    function testWriteNormalCase() public {
        _write({
            user: Constants.WRITER1,
            optionAmount: 3267 * (10**optionToken.decimals()),
            expectedUnderlyingAmount: 3267 * (10**underlyingToken.decimals())
        });

        _write({
            user: Constants.WRITER1,
            optionAmount: 7422 * (10**(optionToken.decimals() - 10)),
            expectedUnderlyingAmount: 7422 * (10**(underlyingToken.decimals() - 10))
        });
    }

    function testWriteRoundDownCase() public {
        _write({
            user: Constants.WRITER1,
            optionAmount: 12345678901234567890,
            expectedUnderlyingAmount: 1234567890123457
        });
    }

    function testWriteUnderQuotePrecisionComplement() public {
        vm.expectRevert("INVALID_AMOUNT");
        optionToken.write(0);

        optionToken.write(1);
    }

    function testWriteWhenOptionExpired() public {
        vm.warp(1 days + 1);
        uint256 amount = 1000 * (10**optionToken.decimals());
        vm.expectRevert("OPTION_EXPIRED");
        optionToken.write(amount);
    }
}
