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

contract PutOptionExerciseUnitTest is Test {
    event Exercise(address indexed recipient, uint256 amount);

    uint256 constant STRIKE_PRICE = 232005 * 10**17; // $23200.5
    uint256 constant EXERCISE_FEE = 2500; // 0.25%

    PutOptionToken optionToken;

    MockQuoteToken quoteToken;
    MockUnderlyingToken underlyingToken;

    function setUp() public {
        (quoteToken, underlyingToken, optionToken) = (new PutOptionTokenUnitTestSetUp()).run(
            STRIKE_PRICE,
            EXERCISE_FEE
        );
    }

    function _exercise(
        address user,
        uint256 optionAmount,
        uint256 expectedQuoteAmount,
        uint256 expectedUnderlyingAmount
    ) private {
        uint256 beforeOptionBalance = optionToken.balanceOf(user);
        uint256 beforeQuoteBalance = quoteToken.balanceOf(user);
        uint256 beforeUnderlyingBalance = underlyingToken.balanceOf(user);
        uint256 beforeExerciseBalance = optionToken.exercisedAmount();

        vm.expectEmit(true, false, false, true);
        emit Exercise(user, optionAmount);
        vm.prank(user);
        optionToken.exercise(optionAmount);

        assertEq(optionToken.balanceOf(user), beforeOptionBalance - optionAmount, "EXERCISE_OPTION_BALANCE");
        assertEq(quoteToken.balanceOf(user), beforeQuoteBalance + expectedQuoteAmount, "EXERCISE_QUOTE_BALANCE");
        assertEq(
            underlyingToken.balanceOf(user),
            beforeUnderlyingBalance - expectedUnderlyingAmount,
            "EXERCISE_UNDERLYING_BALANCE"
        );
        assertEq(optionToken.exercisedAmount() - beforeExerciseBalance, optionAmount, "EXERCISE_EXERCISE_BALANCE");
    }

    function testSelfExerciseNormalCase() public {
        uint256 optionAmount = 1 * (10**optionToken.decimals());
        vm.prank(Constants.EXERCISER);
        optionToken.write(optionAmount);
        assertEq(optionToken.balanceOf(Constants.EXERCISER), optionAmount, "BEFORE_OPTION_BALANCE");

        _exercise({
            user: Constants.EXERCISER,
            optionAmount: optionAmount,
            expectedQuoteAmount: (232005 * (10**quoteToken.decimals()) * (Constants.FEE_PRECISION - EXERCISE_FEE)) /
                Constants.FEE_PRECISION /
                10,
            expectedUnderlyingAmount: 1 * (10**underlyingToken.decimals())
        });
    }

    function testSelfExerciseRoundDownCase() public {
        uint256 optionAmount = (1 * (10**optionToken.decimals())) / 3;
        vm.prank(Constants.EXERCISER);
        optionToken.write(optionAmount);
        assertEq(optionToken.balanceOf(Constants.EXERCISER), optionAmount, "BEFORE_OPTION_BALANCE");

        _exercise({
            user: Constants.EXERCISER,
            optionAmount: optionAmount,
            // (optionAmount * strikePrice) - fee
            expectedQuoteAmount: 7733499999 - 19333750,
            expectedUnderlyingAmount: (1 * (10**underlyingToken.decimals())) / 3
        });
    }

    function testOtherUserExercise() public {
        uint256 optionAmount = 1 * (10**optionToken.decimals());
        vm.prank(Constants.WRITER1);
        optionToken.write(optionAmount);
        assertEq(optionToken.balanceOf(Constants.WRITER1), optionAmount, "BEFORE_OPTION_BALANCE");

        // transfer option token to exerciser
        vm.prank(Constants.WRITER1);
        optionToken.transfer(Constants.EXERCISER, optionAmount);

        _exercise({
            user: Constants.EXERCISER,
            optionAmount: optionAmount,
            expectedQuoteAmount: (232005 * (10**quoteToken.decimals()) * (Constants.FEE_PRECISION - EXERCISE_FEE)) /
                Constants.FEE_PRECISION /
                10,
            expectedUnderlyingAmount: 1 * (10**underlyingToken.decimals())
        });
    }

    function testExerciseUnderQuotePrecisionComplement() public {
        vm.expectRevert("INVALID_AMOUNT");
        optionToken.exercise(0);

        vm.expectRevert("INVALID_AMOUNT");
        optionToken.exercise(1);

        uint256 maximumAmountToRevert = 4310; // (Constants.PRICE_PRECISION * 10**(optionToken.decimals() - quoteToken.decimals())) / STRIKE_PRICE
        vm.expectRevert("INVALID_AMOUNT");
        optionToken.exercise(maximumAmountToRevert);

        uint256 minimumAmountToNotRevert = maximumAmountToRevert + 1;
        optionToken.write(minimumAmountToNotRevert);
        optionToken.exercise(minimumAmountToNotRevert);
    }

    function testExerciseOptionExpired() public {
        vm.warp(1 days + 1);
        uint256 amount = 1000 * (10**optionToken.decimals());
        vm.expectRevert("OPTION_EXPIRED");
        optionToken.exercise(amount);
    }
}
