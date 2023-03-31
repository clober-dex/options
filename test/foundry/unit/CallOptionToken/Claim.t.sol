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

contract CallOptionClaimUnitTest is Test {
    event Claim(address indexed recipient, uint256 amount);

    uint256 constant STRIKE_PRICE = 5324 * 10**15; // $5.324
    uint256 constant EXERCISE_FEE = 100; // 0.01%

    CallOptionToken optionToken;

    MockQuoteToken quoteToken;
    MockUnderlyingToken underlyingToken;

    function setUp() public {
        (quoteToken, underlyingToken, optionToken) = (new CallOptionTokenUnitTestSetUp()).run(
            STRIKE_PRICE,
            EXERCISE_FEE
        );
    }

    function _claim(
        address user,
        uint256 expectedQuoteAmount,
        uint256 expectedUnderlyingAmount
    ) private {
        uint256 beforeQuoteBalance = quoteToken.balanceOf(user);
        uint256 beforeUnderlyingBalance = underlyingToken.balanceOf(user);

        vm.expectEmit(true, false, false, true);
        emit Claim(user, optionToken.collateral(user));
        vm.prank(user);
        optionToken.claim();

        assertEq(quoteToken.balanceOf(user) - beforeQuoteBalance, expectedQuoteAmount, "CLAIM_QUOTE_BALANCE");
        assertEq(
            underlyingToken.balanceOf(user) - beforeUnderlyingBalance,
            expectedUnderlyingAmount,
            "CLAIM_UNDERLYING_BALANCE"
        );
        assertEq(optionToken.collateral(user), 0, "CLAIM_COLLATERAL_BALANCE");
    }

    function testClaimNoOneExercised() public {
        uint256 optionAmount1 = 456 * (10**optionToken.decimals());
        vm.prank(Constants.WRITER1);
        optionToken.write(optionAmount1);

        uint256 optionAmount2 = 876 * (10**optionToken.decimals());
        vm.prank(Constants.WRITER2);
        optionToken.write(optionAmount2);

        vm.warp(1 days + 1);
        _claim({
            user: Constants.WRITER1,
            expectedQuoteAmount: 0,
            // No one exercised, so underlying amount is 0
            expectedUnderlyingAmount: optionAmount1
        });

        _claim({
            user: Constants.WRITER2,
            expectedQuoteAmount: 0,
            // No one exercised, so underlying amount is 0
            expectedUnderlyingAmount: optionAmount2
        });
    }

    function testClaimHalfExercised() public {
        uint256 optionAmount1 = 132 * (10**optionToken.decimals()) + 1;
        vm.prank(Constants.WRITER1);
        optionToken.write(optionAmount1);
        assertEq(optionToken.balanceOf(Constants.WRITER1), optionAmount1, "BEFORE_OPTION_BALANCE");

        uint256 optionAmount2 = 12441 * (10**(optionToken.decimals() - 10)) + 1;
        vm.prank(Constants.WRITER2);
        optionToken.write(optionAmount2);
        assertEq(optionToken.balanceOf(Constants.WRITER2), optionAmount2, "BEFORE_OPTION_BALANCE");

        // transfer option token to exerciser
        vm.prank(Constants.WRITER1);
        optionToken.transfer(Constants.EXERCISER, optionAmount1);

        // half exercised
        vm.prank(Constants.EXERCISER);
        optionToken.exercise(optionAmount1 / 2);

        vm.warp(1 days + 1);
        _claim({
            user: Constants.WRITER1,
            // STRIKE_PRICE * (optionAmount1 + optionAmount2 - optionAmount1 / 2) * (optionAmount1 / (optionAmount1 + optionAmount2))
            expectedQuoteAmount: (STRIKE_PRICE * 66 * 10**quoteToken.decimals() * optionAmount1) /
                10**18 /
                (optionAmount1 + optionAmount2),
            expectedUnderlyingAmount: (optionAmount1 * (optionAmount1 / 2 + 1 + optionAmount2)) /
                (optionAmount1 + optionAmount2)
        });
        _claim({
            user: Constants.WRITER2,
            // STRIKE_PRICE * (optionAmount1 + optionAmount2 - optionAmount1 / 2) * (optionAmount1 / (optionAmount1 + optionAmount2))
            expectedQuoteAmount: (STRIKE_PRICE * 66 * 10**quoteToken.decimals() * optionAmount2) /
                10**18 /
                (optionAmount1 + optionAmount2),
            expectedUnderlyingAmount: (optionAmount2 * (optionAmount1 / 2 + 1 + optionAmount2)) /
                (optionAmount1 + optionAmount2)
        });
    }

    function testClaimAllExercised() public {
        uint256 optionAmount1 = 1234 * (10**optionToken.decimals());
        vm.prank(Constants.WRITER1);
        optionToken.write(optionAmount1);

        uint256 optionAmount2 = 5678 * (10**optionToken.decimals());
        vm.prank(Constants.WRITER2);
        optionToken.write(optionAmount2);

        // transfer option token to exerciser
        vm.prank(Constants.WRITER1);
        optionToken.transfer(Constants.EXERCISER, optionAmount1);

        // all exercised
        vm.prank(Constants.EXERCISER);
        optionToken.exercise(optionAmount1);

        vm.warp(1 days + 1);
        _claim({
            user: Constants.WRITER1,
            // STRIKE_PRICE * (optionAmount1 + optionAmount2 - optionAmount1) * (optionAmount1 / (optionAmount1 + optionAmount2))
            expectedQuoteAmount: (STRIKE_PRICE * 1234 * 10**quoteToken.decimals() * optionAmount1) /
                10**18 /
                (optionAmount1 + optionAmount2),
            expectedUnderlyingAmount: (optionAmount1 * optionAmount2) / (optionAmount1 + optionAmount2)
        });
    }

    function testClaimBeforeExpiration() public {
        vm.prank(Constants.WRITER1);
        optionToken.write(2000 * (10**optionToken.decimals()));

        vm.prank(Constants.WRITER1);
        vm.expectRevert("OPTION_NOT_EXPIRED");
        optionToken.claim();
    }
}
