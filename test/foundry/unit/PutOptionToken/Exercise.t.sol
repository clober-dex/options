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

    PutOptionToken optionToken;

    MockQuoteToken quoteToken;
    MockUnderlyingToken underlyingToken;

    function setUp() public {
        (quoteToken, underlyingToken, optionToken) = (new PutOptionTokenUnitTestSetUp()).run();
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
        uint256 _optionAmount = 2000 * (10**optionToken.decimals());
        vm.prank(Constants.EXERCISER);
        optionToken.write(_optionAmount);
        assertEq(optionToken.balanceOf(Constants.EXERCISER), _optionAmount, "BEFORE_OPTION_BALANCE");

        _exercise({
            user: Constants.EXERCISER,
            optionAmount: _optionAmount,
            expectedQuoteAmount: (1000 * (10**quoteToken.decimals()) * (Constants.FEE_PRECISION - Constants.FEE)) /
                Constants.FEE_PRECISION,
            // underlying and option decimals are same
            expectedUnderlyingAmount: 2000 * (10**underlyingToken.decimals())
        });
    }

    function testSelfExerciseRoundDownCase() public {
        uint256 _optionAmount = 3333333333333333333;
        vm.prank(Constants.EXERCISER);
        optionToken.write(_optionAmount);
        assertEq(optionToken.balanceOf(Constants.EXERCISER), _optionAmount, "BEFORE_OPTION_BALANCE");

        _exercise({
            user: Constants.EXERCISER,
            optionAmount: _optionAmount,
            // our contract lose quote token (1 WEI)
            expectedQuoteAmount: 1666666 - 1667,
            // underlying and option decimals are same
            expectedUnderlyingAmount: _optionAmount
        });
    }

    function testOtherUserExercise() public {
        uint256 _optionAmount = 2000 * (10**optionToken.decimals());
        vm.prank(Constants.WRITER1);
        optionToken.write(_optionAmount);
        assertEq(optionToken.balanceOf(Constants.WRITER1), _optionAmount, "BEFORE_OPTION_BALANCE");

        // transfer option token to exerciser
        vm.prank(Constants.WRITER1);
        optionToken.transfer(Constants.EXERCISER, _optionAmount);

        _exercise({
            user: Constants.EXERCISER,
            optionAmount: _optionAmount,
            expectedQuoteAmount: (1000 * (10**quoteToken.decimals()) * (Constants.FEE_PRECISION - Constants.FEE)) /
                Constants.FEE_PRECISION,
            // underlying and option decimals are same
            expectedUnderlyingAmount: 2000 * (10**underlyingToken.decimals())
        });
    }

    function testExerciseUnderQuotePrecisionComplement() public {
        vm.expectRevert("INVALID_AMOUNT");
        optionToken.exercise(0);

        vm.expectRevert("INVALID_AMOUNT");
        optionToken.exercise(1);

        uint256 _maximumAmountToRevert = 2 * 10**(18 - quoteToken.decimals()) - 1;
        vm.expectRevert("INVALID_AMOUNT");
        optionToken.exercise(_maximumAmountToRevert);

        uint256 _minimumAmountToNotRevert = 2 * 10**(18 - quoteToken.decimals());
        optionToken.write(_minimumAmountToNotRevert);
        optionToken.exercise(_minimumAmountToNotRevert);
    }

    function testExerciseOptionExpired() public {
        vm.warp(1 days + 1);
        uint256 _amount = 1000 * (10**optionToken.decimals());
        vm.expectRevert("OPTION_EXPIRED");
        optionToken.exercise(_amount);
    }
}
