// SPDX-License-Identifier: -
// License: https://license.clober.io/LICENSE.pdf

pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "../Constants.sol";
import "../../../mocks/MockQuoteToken.sol";
import "../../../mocks/MockUnderlyingToken.sol";
import "../../../../contracts/arbitrum/Arbitrum$1PutOption.sol";

contract $1PutOptionUnitTest is Test {
    event Write(address indexed writer, uint256 amount);
    event Cancel(address indexed writer, uint256 amount);
    event Exercise(address indexed recipient, uint256 amount);
    event Claim(address indexed recipient, uint256 amount);
    event CollectFee(address indexed recipient, uint256 amount);

    Arbitrum$1PutOption optionToken;

    MockQuoteToken quoteToken;
    MockUnderlyingToken underlyingToken;

    function setUp() public {
        quoteToken = new MockQuoteToken();
        underlyingToken = new MockUnderlyingToken();

        optionToken = new Arbitrum$1PutOption(address(underlyingToken), address(quoteToken), 1 days);

        // mint some tokens to the writers
        quoteToken.mint(address(this), 10000000 * (10**quoteToken.decimals()));
        quoteToken.mint(Constants.WRITER1, 10000000 * (10**quoteToken.decimals()));
        quoteToken.mint(Constants.WRITER2, 10000000 * (10**quoteToken.decimals()));
        quoteToken.mint(Constants.WRITER3, 10000000 * (10**quoteToken.decimals()));
        quoteToken.mint(Constants.EXERCISER, 10000000 * (10**quoteToken.decimals()));

        underlyingToken.mint(address(this), 10000000 * (10**underlyingToken.decimals()));
        underlyingToken.mint(Constants.EXERCISER, 10000000 * (10**underlyingToken.decimals()));

        // approve the option token to spend the quote tokens
        vm.prank(address(this));
        quoteToken.approve(address(optionToken), type(uint256).max);
        vm.prank(Constants.WRITER1);
        quoteToken.approve(address(optionToken), type(uint256).max);
        vm.prank(Constants.WRITER2);
        quoteToken.approve(address(optionToken), type(uint256).max);
        vm.prank(Constants.WRITER3);
        quoteToken.approve(address(optionToken), type(uint256).max);
        vm.prank(Constants.EXERCISER);
        quoteToken.approve(address(optionToken), type(uint256).max);

        // approve the option token to spend the underlying tokens
        vm.prank(address(this));
        underlyingToken.approve(address(optionToken), type(uint256).max);
        vm.prank(Constants.EXERCISER);
        underlyingToken.approve(address(optionToken), type(uint256).max);
    }

    function testTokenIsMapped() public {
        assertEq(optionToken.underlyingToken(), address(underlyingToken), "UNDERLYING_TOKEN");
        assertEq(optionToken.quoteToken(), address(quoteToken), "QUOTE_TOKEN");
    }

    function _write(
        address user,
        uint256 optionAmount,
        uint256 expectedOptionAmount,
        uint256 expectedQuoteAmount
    ) private {
        uint256 beforeOptionBalance = optionToken.balanceOf(user);
        uint256 beforeQuoteBalance = quoteToken.balanceOf(user);
        uint256 beforeCollateralBalance = optionToken.collateral(user);

        vm.expectEmit(true, false, false, true);
        emit Write(user, expectedOptionAmount);
        vm.prank(user);
        optionToken.write(optionAmount);

        assertEq(optionToken.balanceOf(user), beforeOptionBalance + expectedOptionAmount, "WRITE_OPTION_BALANCE");
        assertEq(quoteToken.balanceOf(user), beforeQuoteBalance - expectedQuoteAmount, "WRITE_QUOTE_BALANCE");
        assertEq(
            optionToken.collateral(user),
            beforeCollateralBalance + expectedQuoteAmount,
            "WRITE_COLLATERAL_BALANCE"
        );
    }

    function testWriteNormalCase() public {
        _write({
            user: Constants.WRITER1,
            optionAmount: 2000 * (10**optionToken.decimals()),
            expectedOptionAmount: 2000 * (10**optionToken.decimals()),
            expectedQuoteAmount: 2000 * (10**quoteToken.decimals())
        });
    }

    function testWriteRoundDownCase() public {
        _write({
            user: Constants.WRITER1,
            optionAmount: 3333333333333333333,
            expectedOptionAmount: 3333333000000000000,
            expectedQuoteAmount: 3333333
        });
    }

    function testWriteUnderQuotePrecisionComplement() public {
        vm.expectRevert("INVALID_AMOUNT");
        optionToken.write(0);

        vm.expectRevert("INVALID_AMOUNT");
        optionToken.write(1);

        uint256 _maximumAmountToRevert = 10**(18 - quoteToken.decimals()) - 1;
        vm.expectRevert("INVALID_AMOUNT");
        optionToken.write(_maximumAmountToRevert);

        uint256 _minimumAmountToNotRevert = 10**(18 - quoteToken.decimals());
        optionToken.write(_minimumAmountToNotRevert);
    }

    function testWriteWhenOptionExpired() public {
        vm.warp(1 days + 1);
        uint256 _amount = 1000 * (10**optionToken.decimals());
        vm.expectRevert("OPTION_EXPIRED");
        optionToken.write(_amount);
    }

    function _cancel(
        address user,
        uint256 optionAmount,
        uint256 expectedOptionAmount,
        uint256 expectedQuoteAmount
    ) private {
        uint256 beforeOptionBalance = optionToken.balanceOf(user);
        uint256 beforeQuoteBalance = quoteToken.balanceOf(user);
        uint256 beforeCollateralBalance = optionToken.collateral(user);

        vm.expectEmit(true, false, false, true);
        emit Cancel(user, expectedOptionAmount);
        vm.prank(user);
        optionToken.cancel(optionAmount);

        assertEq(optionToken.balanceOf(user), beforeOptionBalance - expectedOptionAmount, "CANCEL_OPTION_BALANCE");
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
            expectedOptionAmount: 1000 * (10**optionToken.decimals()),
            expectedQuoteAmount: 1000 * (10**quoteToken.decimals())
        });

        _cancel({
            user: Constants.WRITER1,
            optionAmount: 1000 * (10**optionToken.decimals()),
            expectedOptionAmount: 1000 * (10**optionToken.decimals()),
            expectedQuoteAmount: 1000 * (10**quoteToken.decimals())
        });
        assertEq(optionToken.balanceOf(Constants.WRITER1), 0, "BEFORE_AFTER_BALANCE");
    }

    function testCancelRoundDownCase() public {
        uint256 _optionAmount = 3333333333333333333;
        uint256 _expectedOptionAmount = 3333333000000000000;
        vm.prank(Constants.WRITER1);
        optionToken.write(_optionAmount);
        assertEq(optionToken.balanceOf(Constants.WRITER1), _expectedOptionAmount, "BEFORE_OPTION_BALANCE");

        _cancel({
            user: Constants.WRITER1,
            optionAmount: 1666666666666666666,
            expectedOptionAmount: 1666666000000000000,
            expectedQuoteAmount: 1666666
        });

        _cancel({
            user: Constants.WRITER1,
            optionAmount: optionToken.balanceOf(Constants.WRITER1),
            expectedOptionAmount: 1666667000000000000,
            expectedQuoteAmount: 1666667
        });
        assertEq(optionToken.balanceOf(Constants.WRITER1), 0, "BEFORE_AFTER_BALANCE");
    }

    function testCancelUnderQuotePrecisionComplement() public {
        vm.expectRevert("INVALID_AMOUNT");
        optionToken.cancel(0);

        vm.expectRevert("INVALID_AMOUNT");
        optionToken.cancel(1);

        uint256 _maximumAmountToRevert = 10**(18 - quoteToken.decimals()) - 1;
        vm.expectRevert("INVALID_AMOUNT");
        optionToken.cancel(_maximumAmountToRevert);

        uint256 _minimumAmountToNotRevert = 10**(18 - quoteToken.decimals());
        optionToken.write(_minimumAmountToNotRevert);
        optionToken.cancel(_minimumAmountToNotRevert);
    }

    function testCancelOptionExpired() public {
        vm.warp(1 days + 1);
        uint256 _amount = 1000 * (10**optionToken.decimals());
        vm.expectRevert("OPTION_EXPIRED");
        optionToken.cancel(_amount);
    }

    function _exercise(
        address user,
        uint256 optionAmount,
        uint256 expectedOptionAmount,
        uint256 expectedQuoteAmount,
        uint256 expectedUnderlyingAmount
    ) private {
        uint256 beforeOptionBalance = optionToken.balanceOf(user);
        uint256 beforeQuoteBalance = quoteToken.balanceOf(user);
        uint256 beforeUnderlyingBalance = underlyingToken.balanceOf(user);
        uint256 beforeExerciseBalance = optionToken.exercisedAmount();

        vm.expectEmit(true, false, false, true);
        emit Exercise(user, expectedOptionAmount);
        vm.prank(user);
        optionToken.exercise(optionAmount);

        assertEq(optionToken.balanceOf(user), beforeOptionBalance - expectedOptionAmount, "EXERCISE_OPTION_BALANCE");
        assertEq(quoteToken.balanceOf(user), beforeQuoteBalance + expectedQuoteAmount, "EXERCISE_QUOTE_BALANCE");
        assertEq(
            underlyingToken.balanceOf(user),
            beforeUnderlyingBalance - expectedUnderlyingAmount,
            "EXERCISE_UNDERLYING_BALANCE"
        );
        assertEq(
            optionToken.exercisedAmount() - beforeExerciseBalance,
            expectedOptionAmount,
            "EXERCISE_EXERCISE_BALANCE"
        );
    }

    function testSelfExerciseNormalCase() public {
        uint256 _optionAmount = 2000 * (10**optionToken.decimals());
        vm.prank(Constants.EXERCISER);
        optionToken.write(_optionAmount);
        assertEq(optionToken.balanceOf(Constants.EXERCISER), _optionAmount, "BEFORE_OPTION_BALANCE");

        _exercise({
            user: Constants.EXERCISER,
            optionAmount: _optionAmount,
            expectedOptionAmount: _optionAmount,
            expectedQuoteAmount: (2000 * (10**quoteToken.decimals()) * (Constants.FEE_PRECISION - Constants.FEE)) /
                Constants.FEE_PRECISION,
            // underlying and option decimals are same
            expectedUnderlyingAmount: 2000 * (10**underlyingToken.decimals())
        });
    }

    function testSelfExerciseRoundDownCase() public {
        uint256 _optionAmount = 3333333333333333333;
        uint256 _expectedOptionAmount = 3333333000000000000;
        vm.prank(Constants.EXERCISER);
        optionToken.write(_optionAmount);
        assertEq(optionToken.balanceOf(Constants.EXERCISER), _expectedOptionAmount, "BEFORE_OPTION_BALANCE");

        _exercise({
            user: Constants.EXERCISER,
            optionAmount: _optionAmount,
            expectedOptionAmount: _expectedOptionAmount,
            // our contract lose quote token (1 WEI)
            expectedQuoteAmount: ((3333333 * (Constants.FEE_PRECISION - Constants.FEE)) / Constants.FEE_PRECISION) + 1,
            // underlying and option decimals are same
            expectedUnderlyingAmount: _expectedOptionAmount
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
            expectedOptionAmount: _optionAmount,
            expectedQuoteAmount: (2000 * (10**quoteToken.decimals()) * (Constants.FEE_PRECISION - Constants.FEE)) /
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

        uint256 _maximumAmountToRevert = 10**(18 - quoteToken.decimals()) - 1;
        vm.expectRevert("INVALID_AMOUNT");
        optionToken.exercise(_maximumAmountToRevert);

        uint256 _minimumAmountToNotRevert = 10**(18 - quoteToken.decimals());
        optionToken.write(_minimumAmountToNotRevert);
        optionToken.exercise(_minimumAmountToNotRevert);
    }

    function testExerciseOptionExpired() public {
        vm.warp(1 days + 1);
        uint256 _amount = 1000 * (10**optionToken.decimals());
        vm.expectRevert("OPTION_EXPIRED");
        optionToken.exercise(_amount);
    }

    function _claim(
        address user,
        uint256 expectedOptionAmount,
        uint256 expectedQuoteAmount,
        uint256 expectedUnderlyingAmount
    ) private {
        uint256 beforeQuoteBalance = quoteToken.balanceOf(user);
        uint256 beforeUnderlyingBalance = underlyingToken.balanceOf(user);

        vm.expectEmit(true, false, false, true);
        emit Claim(user, expectedOptionAmount);
        vm.prank(user);
        optionToken.claim();

        assertEq(quoteToken.balanceOf(user), beforeQuoteBalance + expectedQuoteAmount, "CLAIM_QUOTE_BALANCE");
        assertEq(
            underlyingToken.balanceOf(user),
            beforeUnderlyingBalance + expectedUnderlyingAmount,
            "CLAIM_UNDERLYING_BALANCE"
        );
        assertEq(optionToken.collateral(user), 0, "CLAIM_COLLATERAL_BALANCE");
    }

    function testClaimNoOneExercised() public {
        uint256 _optionAmount1 = 2000 * (10**optionToken.decimals());
        vm.prank(Constants.WRITER1);
        optionToken.write(_optionAmount1);
        assertEq(optionToken.balanceOf(Constants.WRITER1), _optionAmount1, "BEFORE_OPTION_BALANCE");

        uint256 _optionAmount2 = 3000 * (10**optionToken.decimals());
        vm.prank(Constants.WRITER2);
        optionToken.write(_optionAmount2);
        assertEq(optionToken.balanceOf(Constants.WRITER2), _optionAmount2, "BEFORE_OPTION_BALANCE");

        vm.warp(1 days + 1);
        _claim({
            user: Constants.WRITER1,
            expectedOptionAmount: _optionAmount1,
            expectedQuoteAmount: 2000 * (10**quoteToken.decimals()),
            // No one exercised, so underlying amount is 0
            expectedUnderlyingAmount: 0
        });

        _claim({
            user: Constants.WRITER2,
            expectedOptionAmount: _optionAmount2,
            expectedQuoteAmount: 3000 * (10**quoteToken.decimals()),
            // No one exercised, so underlying amount is 0
            expectedUnderlyingAmount: 0
        });
    }

    function testClaimHalfExercised() public {
        uint256 _optionAmount1 = 2000 * (10**optionToken.decimals());
        vm.prank(Constants.WRITER1);
        optionToken.write(_optionAmount1);
        assertEq(optionToken.balanceOf(Constants.WRITER1), _optionAmount1, "BEFORE_OPTION_BALANCE");

        uint256 _optionAmount2 = 3000 * (10**optionToken.decimals());
        vm.prank(Constants.WRITER2);
        optionToken.write(_optionAmount2);
        assertEq(optionToken.balanceOf(Constants.WRITER2), _optionAmount2, "BEFORE_OPTION_BALANCE");

        // transfer option token to exerciser
        vm.prank(Constants.WRITER1);
        optionToken.transfer(Constants.EXERCISER, _optionAmount1);

        // half exercised
        vm.prank(Constants.EXERCISER);
        optionToken.exercise(_optionAmount1 / 2);

        vm.warp(1 days + 1);
        _claim({
            user: Constants.WRITER1,
            expectedOptionAmount: _optionAmount1,
            // 2000 * 1e6 * (4000 * 1e18 / (4000 * 1e18 + 1000 * 1e18))
            expectedQuoteAmount: (2000 * (10**quoteToken.decimals()) * 4) / 5,
            // (1000 * 1e6 / 0.5 * 1e-12) * (1000 * 1e18 / (4000 * 1e18 + 1000 * 1e18))
            expectedUnderlyingAmount: (2000 * (10**underlyingToken.decimals()) * 1) / 5
        });
    }

    function testClaimAllExercised() public {
        uint256 _optionAmount1 = 2000 * (10**optionToken.decimals());
        vm.prank(Constants.WRITER1);
        optionToken.write(_optionAmount1);
        assertEq(optionToken.balanceOf(Constants.WRITER1), _optionAmount1, "BEFORE_OPTION_BALANCE");

        uint256 _optionAmount2 = 3000 * (10**optionToken.decimals());
        vm.prank(Constants.WRITER2);
        optionToken.write(_optionAmount2);
        assertEq(optionToken.balanceOf(Constants.WRITER2), _optionAmount2, "BEFORE_OPTION_BALANCE");

        // transfer option token to exerciser
        vm.prank(Constants.WRITER1);
        optionToken.transfer(Constants.EXERCISER, _optionAmount1);

        // all exercised
        vm.prank(Constants.EXERCISER);
        optionToken.exercise(_optionAmount1);

        vm.warp(1 days + 1);
        _claim({
            user: Constants.WRITER1,
            expectedOptionAmount: _optionAmount1,
            // 2000 * 1e6 * (3000 * 1e18 / (3000 * 1e18 + 2000 * 1e18))
            expectedQuoteAmount: (2000 * (10**quoteToken.decimals()) * 3) / 5,
            // (1000 * 1e6 / 0.5 * 1e-12) * (2000 * 1e18 / (3000 * 1e18 + 2000 * 1e18))
            expectedUnderlyingAmount: (2000 * (10**underlyingToken.decimals()) * 2) / 5
        });
    }

    function testClaimBeforeExpiration() public {
        vm.prank(Constants.WRITER1);
        optionToken.write(2000 * (10**optionToken.decimals()));

        vm.prank(Constants.WRITER1);
        vm.expectRevert("OPTION_NOT_EXPIRED");
        optionToken.claim();
    }

    function testCollectFee() public {
        assertEq(optionToken.owner(), address(this), "OWNER");

        testSelfExerciseNormalCase();

        uint256 expectedFee = (2000 * (10**quoteToken.decimals()) * Constants.FEE) / Constants.FEE_PRECISION;

        vm.expectEmit(true, false, false, true);
        emit CollectFee(address(this), expectedFee);
        vm.prank(address(this));
        optionToken.collectFee();

        assertEq(optionToken.exerciseFeeBalance(), 0, "EXERCISE_FEE_BALANCE");
    }
}
