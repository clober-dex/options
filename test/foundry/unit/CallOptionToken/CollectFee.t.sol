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

contract CallOptionCollectFeeUnitTest is Test {
    event CollectFee(address indexed recipient, uint256 amount);

    uint256 constant EXERCISE_FEE = 3000; // 0.3%

    CallOptionToken optionToken;

    MockQuoteToken quoteToken;
    MockUnderlyingToken underlyingToken;

    function setUp() public {
        (quoteToken, underlyingToken, optionToken) = (new CallOptionTokenUnitTestSetUp()).run(
            2423428 * 10**14, // $242.3428
            EXERCISE_FEE
        );
    }

    function testCollectFee() public {
        assertEq(optionToken.owner(), address(this), "OWNER");

        uint256 optionAmount = 4834 * (10**optionToken.decimals());
        vm.prank(Constants.EXERCISER);
        optionToken.write(optionAmount);
        assertEq(optionToken.balanceOf(Constants.EXERCISER), optionAmount, "BEFORE_OPTION_BALANCE");

        vm.prank(Constants.EXERCISER);
        optionToken.exercise(optionAmount);

        uint256 beforeFeeBalance = underlyingToken.balanceOf(address(this));
        uint256 expectedFee = (4834 * (10**underlyingToken.decimals()) * EXERCISE_FEE) / Constants.FEE_PRECISION;

        vm.expectEmit(true, false, false, true);
        emit CollectFee(address(this), expectedFee);
        vm.prank(address(this));
        optionToken.collectFee();

        assertEq(optionToken.exerciseFeeBalance(), 0, "EXERCISE_FEE_BALANCE");
        assertEq(underlyingToken.balanceOf(address(this)) - beforeFeeBalance, expectedFee, "EXERCISE_FEE_BALANCE");
    }
}
