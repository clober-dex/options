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

contract CallOptionCancelUnitTest is Test {
    event Cancel(address indexed writer, uint256 amount);

    uint256 constant STRIKE_PRICE = 1458 * 10**12; // $0.001458
    uint256 constant EXERCISE_FEE = 1000;

    CallOptionToken optionToken;

    MockQuoteToken quoteToken;
    MockUnderlyingToken underlyingToken;

    function setUp() public {
        (quoteToken, underlyingToken, optionToken) = (new CallOptionTokenUnitTestSetUp()).run(
            STRIKE_PRICE,
            EXERCISE_FEE
        );
    }

    function _cancel(
        address user,
        uint256 optionAmount,
        uint256 expectedUnderlyingAmount
    ) private {
        uint256 beforeOptionBalance = optionToken.balanceOf(user);
        uint256 beforeUnderlyingBalance = underlyingToken.balanceOf(user);
        uint256 beforeCollateralBalance = optionToken.collateral(user);

        vm.expectEmit(true, false, false, true);
        emit Cancel(user, optionAmount);
        vm.prank(user);
        optionToken.cancel(optionAmount);

        assertEq(beforeOptionBalance - optionToken.balanceOf(user), optionAmount, "CANCEL_OPTION_BALANCE");
        assertEq(
            underlyingToken.balanceOf(user) - beforeUnderlyingBalance,
            expectedUnderlyingAmount,
            "CANCEL_UNDERLYING_BALANCE"
        );
        assertEq(
            beforeCollateralBalance - optionToken.collateral(user),
            expectedUnderlyingAmount,
            "CANCEL_COLLATERAL_BALANCE"
        );
    }

    function testCancelNormalCase() public {
        uint256 optionAmount = 14 * (10**optionToken.decimals());
        vm.prank(Constants.WRITER1);
        optionToken.write(optionAmount);
        assertEq(optionToken.balanceOf(Constants.WRITER1), optionAmount, "BEFORE_OPTION_BALANCE");

        _cancel({
            user: Constants.WRITER1,
            optionAmount: 9 * (10**optionToken.decimals()),
            expectedUnderlyingAmount: 9 * (10**underlyingToken.decimals())
        });
        assertEq(optionToken.balanceOf(Constants.WRITER1), 5 * (10**optionToken.decimals()), "BEFORE_AFTER_BALANCE");

        _cancel({
            user: Constants.WRITER1,
            optionAmount: 5 * (10**optionToken.decimals()),
            expectedUnderlyingAmount: 5 * (10**underlyingToken.decimals())
        });
        assertEq(optionToken.balanceOf(Constants.WRITER1), 0, "BEFORE_AFTER_BALANCE");
    }

    function testCancelRoundDownCase() public {
        uint256 optionAmount = 11333333333333333333;
        vm.prank(Constants.WRITER1);
        optionToken.write(optionAmount);
        assertEq(optionToken.balanceOf(Constants.WRITER1), optionAmount, "BEFORE_OPTION_BALANCE");

        _cancel({
            user: Constants.WRITER1,
            optionAmount: 11033333333333333332,
            expectedUnderlyingAmount: 11033333333333333332
        });

        _cancel({
            user: Constants.WRITER1,
            optionAmount: 300000000000000001,
            expectedUnderlyingAmount: 300000000000000001
        });
        assertEq(optionToken.balanceOf(Constants.WRITER1), 0, "BEFORE_AFTER_BALANCE");
    }

    function testCancelUnderQuotePrecisionComplement() public {
        vm.expectRevert("INVALID_AMOUNT");
        optionToken.cancel(0);

        vm.prank(Constants.EXERCISER);
        optionToken.write(1);
        vm.prank(Constants.EXERCISER);
        optionToken.cancel(1);
    }

    function testCancelOptionExpired() public {
        vm.warp(1 days + 1);
        uint256 amount = 1000 * (10**optionToken.decimals());
        vm.expectRevert("OPTION_EXPIRED");
        optionToken.cancel(amount);
    }
}
