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

contract PutOptionClaimUnitTest is Test {
    event Claim(address indexed recipient, uint256 amount);

    PutOptionToken optionToken;

    MockQuoteToken quoteToken;
    MockUnderlyingToken underlyingToken;

    function setUp() public {
        (quoteToken, underlyingToken, optionToken) = (new PutOptionTokenUnitTestSetUp()).run(
            1325324 * 10**15, // $132.5324
            100 // 0.01%
        );
    }

    function _claim(
        address user,
        uint256 optionAmount,
        uint256 expectedQuoteAmount,
        uint256 expectedUnderlyingAmount
    ) private {
        uint256 beforeQuoteBalance = quoteToken.balanceOf(user);
        uint256 beforeUnderlyingBalance = underlyingToken.balanceOf(user);

        vm.expectEmit(true, false, false, true);
        emit Claim(user, optionAmount);
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
            optionAmount: _optionAmount1,
            expectedQuoteAmount: 1000 * (10**quoteToken.decimals()),
            // No one exercised, so underlying amount is 0
            expectedUnderlyingAmount: 0
        });

        _claim({
            user: Constants.WRITER2,
            optionAmount: _optionAmount2,
            expectedQuoteAmount: 1500 * (10**quoteToken.decimals()),
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
            optionAmount: _optionAmount1,
            // 1000 * 1e6 * (4000 * 1e18 / (4000 * 1e18 + 1000 * 1e18))
            expectedQuoteAmount: (1000 * (10**quoteToken.decimals()) * 4) / 5,
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
            optionAmount: _optionAmount1,
            // 1000 * 1e6 * (3000 * 1e18 / (3000 * 1e18 + 2000 * 1e18))
            expectedQuoteAmount: (1000 * (10**quoteToken.decimals()) * 3) / 5,
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
}
