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

    uint256 constant STRIKE_PRICE = 3428 * 10**14; // $0.3428
    uint256 constant EXERCISE_FEE = 1000; // 0.1%

    PutOptionToken optionToken;

    MockQuoteToken quoteToken;
    MockUnderlyingToken underlyingToken;

    function setUp() public {
        (quoteToken, underlyingToken, optionToken) = (new PutOptionTokenUnitTestSetUp()).run(
            STRIKE_PRICE,
            EXERCISE_FEE
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
        uint256 optionAmount = 2000 * (10**optionToken.decimals());
        vm.prank(Constants.WRITER1);
        optionToken.write(optionAmount);
        assertEq(optionToken.balanceOf(Constants.WRITER1), optionAmount, "BEFORE_OPTION_BALANCE");

        _cancel({
            user: Constants.WRITER1,
            optionAmount: 1000 * (10**optionToken.decimals()),
            expectedQuoteAmount: (STRIKE_PRICE * 1000 * (10**quoteToken.decimals())) / Constants.PRICE_PRECISION
        });

        _cancel({
            user: Constants.WRITER1,
            optionAmount: 1000 * (10**optionToken.decimals()),
            expectedQuoteAmount: (STRIKE_PRICE * 1000 * (10**quoteToken.decimals())) / Constants.PRICE_PRECISION
        });
        assertEq(optionToken.balanceOf(Constants.WRITER1), 0, "BEFORE_AFTER_BALANCE");
    }

    function testCancelRoundDownCase() public {
        uint256 optionAmount = 333333333333333;
        vm.prank(Constants.WRITER1);
        optionToken.write(optionAmount);
        assertEq(optionToken.balanceOf(Constants.WRITER1), optionAmount, "BEFORE_OPTION_BALANCE");

        _cancel({user: Constants.WRITER1, optionAmount: 166666600000000, expectedQuoteAmount: 571333});

        _cancel({user: Constants.WRITER1, optionAmount: 166666733333333, expectedQuoteAmount: 571333});
        assertEq(optionToken.balanceOf(Constants.WRITER1), 0, "BEFORE_AFTER_BALANCE");
    }

    function testCancelUnderQuotePrecisionComplement() public {
        vm.expectRevert("INVALID_AMOUNT");
        optionToken.cancel(0);

        vm.expectRevert("INVALID_AMOUNT");
        optionToken.cancel(1);

        uint256 maximumAmountToRevert = 291715285; // (Constants.PRICE_PRECISION * 10**(optionToken.decimals() - quoteToken.decimals())) / STRIKE_PRICE
        vm.expectRevert("INVALID_AMOUNT");
        optionToken.cancel(maximumAmountToRevert);

        uint256 minimumAmountToNotRevert = maximumAmountToRevert + 1;
        optionToken.write(minimumAmountToNotRevert);
        optionToken.cancel(minimumAmountToNotRevert);
    }

    function testCancelOptionExpired() public {
        vm.warp(1 days + 1);
        uint256 amount = 1000 * (10**optionToken.decimals());
        vm.expectRevert("OPTION_EXPIRED");
        optionToken.cancel(amount);
    }
}
