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

contract CallOptionExerciseUnitTest is Test {
    event Exercise(address indexed recipient, uint256 amount);

    uint256 constant EXERCISE_FEE = 2500; // 0.25%

    CallOptionToken optionToken;

    MockQuoteToken quoteToken;
    MockUnderlyingToken underlyingToken;

    function setUp() public {
        (quoteToken, underlyingToken, optionToken) = (new CallOptionTokenUnitTestSetUp()).run(
            23200 * 10**18, // $23200
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

        //        vm.expectEmit(true, false, false, true);
        //        emit Exercise(user, optionAmount);
        vm.prank(user);
        optionToken.exercise(optionAmount);

        assertEq(optionToken.balanceOf(user), beforeOptionBalance - optionAmount, "EXERCISE_OPTION_BALANCE");
        assertEq(
            underlyingToken.balanceOf(user) - beforeUnderlyingBalance,
            expectedUnderlyingAmount,
            "EXERCISE_UNDERLYING_BALANCE"
        );
        assertEq(beforeQuoteBalance - quoteToken.balanceOf(user), expectedQuoteAmount, "EXERCISE_QUOTE_BALANCE");
        assertEq(optionToken.exercisedAmount() - beforeExerciseBalance, optionAmount, "EXERCISE_EXERCISE_BALANCE");
    }

    function testSelfExerciseNormalCase() public {
        uint256 optionAmount1 = 142 * (10**optionToken.decimals());
        uint256 optionAmount2 = 7856 * (10**(optionToken.decimals() - 10));
        vm.prank(Constants.EXERCISER);
        optionToken.write(optionAmount1 + optionAmount2);

        _exercise({
            user: Constants.EXERCISER,
            optionAmount: optionAmount1,
            expectedQuoteAmount: 3294400 * (10**quoteToken.decimals()),
            // underlying and option decimals are same
            expectedUnderlyingAmount: 142 *
                (10**underlyingToken.decimals()) -
                (142 * (10**underlyingToken.decimals()) * EXERCISE_FEE) /
                1000000
        });
        _exercise({
            user: Constants.EXERCISER,
            optionAmount: optionAmount2,
            expectedQuoteAmount: 18226,
            // underlying and option decimals are same
            expectedUnderlyingAmount: 7856 *
                (10**(underlyingToken.decimals() - 10)) -
                (7856 * (10**(underlyingToken.decimals() - 10)) * EXERCISE_FEE) /
                1000000
        });
    }

    function testSelfExerciseRoundDownCase() public {
        uint256 optionAmount = 7333333333333333333; // 7.333333333333333333
        vm.prank(Constants.EXERCISER);
        optionToken.write(optionAmount);
        assertEq(optionToken.balanceOf(Constants.EXERCISER), optionAmount, "BEFORE_OPTION_BALANCE");

        _exercise({
            user: Constants.EXERCISER,
            optionAmount: optionAmount,
            // our contract lose quote token (1 WEI)
            expectedQuoteAmount: 170133333334, // 170133.333334 = 23200 * 7333333333333333333 / 10^18 * 10^6
            // underlying and option decimals are same
            expectedUnderlyingAmount: optionAmount /
                10**(optionToken.decimals() - underlyingToken.decimals()) -
                ((optionAmount / 10**(optionToken.decimals() - underlyingToken.decimals())) * EXERCISE_FEE) /
                1000000
        });
    }

    function testOtherUserExercise() public {
        uint256 optionAmount1 = 312 * (10**optionToken.decimals());
        uint256 optionAmount2 = 119 * (10**(optionToken.decimals() - 10));
        vm.prank(Constants.WRITER1);
        optionToken.write(optionAmount1 + optionAmount2);
        assertEq(optionToken.balanceOf(Constants.WRITER1), optionAmount1 + optionAmount2, "BEFORE_OPTION_BALANCE");

        // transfer option token to exerciser
        vm.prank(Constants.WRITER1);
        optionToken.transfer(Constants.EXERCISER, optionAmount1);

        _exercise({
            user: Constants.EXERCISER,
            optionAmount: optionAmount1,
            expectedQuoteAmount: 312 * 23200 * 10**quoteToken.decimals(),
            // underlying and option decimals are same
            expectedUnderlyingAmount: optionAmount1 /
                10**(optionToken.decimals() - underlyingToken.decimals()) -
                ((optionAmount1 / 10**(optionToken.decimals() - underlyingToken.decimals())) * EXERCISE_FEE) /
                1000000
        });

        // transfer option token to exerciser
        vm.prank(Constants.WRITER1);
        optionToken.transfer(Constants.EXERCISER, optionAmount2);

        _exercise({
            user: Constants.EXERCISER,
            optionAmount: optionAmount2,
            expectedQuoteAmount: 277, // 276.08 = 23200 * 119 / 10 ^ 10 * 10 ^ 6
            // underlying and option decimals are same
            expectedUnderlyingAmount: optionAmount2 /
                10**(optionToken.decimals() - underlyingToken.decimals()) -
                ((optionAmount2 / 10**(optionToken.decimals() - underlyingToken.decimals())) * EXERCISE_FEE) /
                1000000
        });
    }

    function testExerciseUnderQuotePrecisionComplement() public {
        vm.expectRevert("INVALID_AMOUNT");
        optionToken.exercise(0);

        vm.prank(Constants.EXERCISER);
        optionToken.write(1);
        vm.prank(Constants.EXERCISER);
        optionToken.exercise(1);
    }

    function testExerciseOptionExpired() public {
        vm.warp(1 days + 1);
        uint256 amount = 1000 * (10**optionToken.decimals());
        vm.expectRevert("OPTION_EXPIRED");
        optionToken.exercise(amount);
    }
}
