// SPDX-License-Identifier: -
// License: https://license.clober.io/LICENSE.pdf

pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "../Constants.sol";
import "../../../../contracts/PutOptionToken.sol";
import "../../../mocks/MockPutOptionToken.sol";
import "../../../mocks/MockQuoteToken.sol";
import "../../../mocks/MockUnderlyingToken.sol";
import "./SetUp.sol";

contract PutOptionCancelUnitTest is Test {
    event Cancel(address indexed writer, uint256 amount);

    PutOptionToken optionToken;

    MockQuoteToken quoteToken;
    MockUnderlyingToken underlyingToken;

    function setUp() public {
        (quoteToken, underlyingToken, optionToken) = (new PutOptionTokenUnitTestSetUp()).run(
            3428 * 10**15, // $0.3428
            1000 // 0.1%
        );
    }

    function _cancel(
        address user,
        uint256 optionAmount,
        uint256 expectedQuoteAmount
    ) private {
        uint256 beforeOptionBalance = optionToken.balanceOf(user);
        uint256 beforeQuoteBalance = quoteToken.balanceOf(user);
        uint256 beforeCollateralBalance = optionToken.collateral(user);

        vm.expectEmit(true, false, false, true);
        emit Cancel(user, optionAmount);
        vm.prank(user);
        optionToken.cancel(optionAmount);

        assertEq(optionToken.balanceOf(user), beforeOptionBalance - optionAmount, "CANCEL_OPTION_BALANCE");
        assertEq(quoteToken.balanceOf(user), beforeQuoteBalance + expectedQuoteAmount, "CANCEL_QUOTE_BALANCE");
        assertEq(
            optionToken.collateral(user),
            beforeCollateralBalance - expectedQuoteAmount,
            "CANCEL_COLLATERAL_BALANCE"
        );
    }

    function testCancelNormalCase() public {
        uint256 _optionAmount = 2000 * (10**optionToken.decimals());
        vm.prank(Constants.WRITER1);
        optionToken.write(_optionAmount);
        assertEq(optionToken.balanceOf(Constants.WRITER1), _optionAmount, "BEFORE_OPTION_BALANCE");

        _cancel({
            user: Constants.WRITER1,
            optionAmount: 1000 * (10**optionToken.decimals()),
            expectedQuoteAmount: 500 * (10**quoteToken.decimals())
        });

        _cancel({
            user: Constants.WRITER1,
            optionAmount: 1000 * (10**optionToken.decimals()),
            expectedQuoteAmount: 500 * (10**quoteToken.decimals())
        });
        assertEq(optionToken.balanceOf(Constants.WRITER1), 0, "BEFORE_AFTER_BALANCE");
    }

    function testCancelRoundDownCase() public {
        uint256 _optionAmount = 3333333333333333333;
        vm.prank(Constants.WRITER1);
        optionToken.write(_optionAmount);
        assertEq(optionToken.balanceOf(Constants.WRITER1), _optionAmount, "BEFORE_OPTION_BALANCE");

        _cancel({user: Constants.WRITER1, optionAmount: 1666666000000000000, expectedQuoteAmount: 833333});

        _cancel({user: Constants.WRITER1, optionAmount: 1666667333333333333, expectedQuoteAmount: 833333});
        assertEq(optionToken.balanceOf(Constants.WRITER1), 0, "BEFORE_AFTER_BALANCE");
    }

    function testCancelUnderQuotePrecisionComplement() public {
        vm.expectRevert("INVALID_AMOUNT");
        optionToken.cancel(0);

        vm.expectRevert("INVALID_AMOUNT");
        optionToken.cancel(1);

        uint256 _maximumAmountToRevert = 2 * 10**(18 - quoteToken.decimals()) - 1;
        vm.expectRevert("INVALID_AMOUNT");
        optionToken.cancel(_maximumAmountToRevert);

        uint256 _minimumAmountToNotRevert = 2 * 10**(18 - quoteToken.decimals());
        optionToken.write(_minimumAmountToNotRevert);
        optionToken.cancel(_minimumAmountToNotRevert);
    }

    function testCancelOptionExpired() public {
        vm.warp(1 days + 1);
        uint256 _amount = 1000 * (10**optionToken.decimals());
        vm.expectRevert("OPTION_EXPIRED");
        optionToken.cancel(_amount);
    }
}
