// SPDX-License-Identifier: -
// License: https://license.clober.io/LICENSE.pdf

pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "../../../mocks/MockQuoteToken.sol";
import "../../../mocks/MockUnderlyingToken.sol";
import "../../../mocks/MockPutOptionToken.sol";
import "../Constants.sol";

contract PutOptionTokenUnitTestSetUp is Test {
    uint256 constant INITIAL_AMOUNT = 10**10;

    function run(uint256 strikePrice, uint256 exerciseFee)
        external
        returns (
            MockQuoteToken quoteToken,
            MockUnderlyingToken underlyingToken,
            MockPutOptionToken optionToken
        )
    {
        address initiator = msg.sender;
        vm.startPrank(initiator);
        quoteToken = new MockQuoteToken();
        underlyingToken = new MockUnderlyingToken();

        // mint some tokens to the writers
        quoteToken.mint(initiator, INITIAL_AMOUNT * (10**quoteToken.decimals()));
        quoteToken.mint(Constants.WRITER1, INITIAL_AMOUNT * (10**quoteToken.decimals()));
        quoteToken.mint(Constants.WRITER2, INITIAL_AMOUNT * (10**quoteToken.decimals()));
        quoteToken.mint(Constants.WRITER3, INITIAL_AMOUNT * (10**quoteToken.decimals()));
        quoteToken.mint(Constants.EXERCISER, INITIAL_AMOUNT * (10**quoteToken.decimals()));

        underlyingToken.mint(initiator, INITIAL_AMOUNT * (10**underlyingToken.decimals()));
        underlyingToken.mint(Constants.EXERCISER, INITIAL_AMOUNT * (10**underlyingToken.decimals()));

        optionToken = new MockPutOptionToken(
            address(underlyingToken),
            address(quoteToken),
            strikePrice,
            Constants.EXPIRES_AT,
            exerciseFee
        );
        vm.stopPrank();

        // approve the option token to spend the quote tokens
        vm.prank(initiator);
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
        vm.prank(initiator);
        underlyingToken.approve(address(optionToken), type(uint256).max);
        vm.prank(Constants.EXERCISER);
        underlyingToken.approve(address(optionToken), type(uint256).max);
    }
}
