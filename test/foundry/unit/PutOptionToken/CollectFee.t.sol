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

contract PutOptionCollectFeeUnitTest is Test {
    event CollectFee(address indexed recipient, uint256 amount);

    PutOptionToken optionToken;

    MockQuoteToken quoteToken;
    MockUnderlyingToken underlyingToken;

    function setUp() public {
        (quoteToken, underlyingToken, optionToken) = (new PutOptionTokenUnitTestSetUp()).run();
    }

    function testCollectFee() public {
        assertEq(optionToken.owner(), address(this), "OWNER");

        uint256 _optionAmount = 2000 * (10**optionToken.decimals());
        vm.prank(Constants.EXERCISER);
        optionToken.write(_optionAmount);
        assertEq(optionToken.balanceOf(Constants.EXERCISER), _optionAmount, "BEFORE_OPTION_BALANCE");

        vm.prank(Constants.EXERCISER);
        optionToken.exercise(_optionAmount);

        uint256 expectedFee = (1000 * (10**quoteToken.decimals()) * Constants.FEE) / Constants.FEE_PRECISION;

        vm.expectEmit(true, false, false, true);
        emit CollectFee(address(this), expectedFee);
        vm.prank(address(this));
        optionToken.collectFee();

        assertEq(optionToken.exerciseFeeBalance(), 0, "EXERCISE_FEE_BALANCE");
    }
}
