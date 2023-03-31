// SPDX-License-Identifier: -
// License: https://license.clober.io/LICENSE.pdf

pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "../../../mocks/MockQuoteToken.sol";
import "../../../mocks/MockUnderlyingToken.sol";
import "../../../mocks/MockCallOptionToken.sol";
import "../Constants.sol";

contract CallOptionTokenUnitTestSetUp is Test {
    function run(uint256 strikePrice, uint256 exerciseFee)
        external
        returns (
            MockQuoteToken quoteToken,
            MockUnderlyingToken underlyingToken,
            MockCallOptionToken optionToken
        )
    {
        address initiator = msg.sender;
        vm.startPrank(initiator);
        quoteToken = new MockQuoteToken();
        underlyingToken = new MockUnderlyingToken();

        // mint some tokens to the writers
        underlyingToken.mint(initiator, 10000000 * (10**underlyingToken.decimals()));
        underlyingToken.mint(Constants.WRITER1, 10000000 * (10**underlyingToken.decimals()));
        underlyingToken.mint(Constants.WRITER2, 10000000 * (10**underlyingToken.decimals()));
        underlyingToken.mint(Constants.WRITER3, 10000000 * (10**underlyingToken.decimals()));
        underlyingToken.mint(Constants.EXERCISER, 10000000 * (10**underlyingToken.decimals()));

        quoteToken.mint(initiator, 10000000 * (10**quoteToken.decimals()));
        quoteToken.mint(Constants.EXERCISER, 10000000 * (10**quoteToken.decimals()));

        optionToken = new MockCallOptionToken(
            address(underlyingToken),
            address(quoteToken),
            strikePrice,
            Constants.EXPIRES_AT,
            exerciseFee
        );
        vm.stopPrank();

        // approve the option token to spend the underlying tokens
        vm.prank(initiator);
        underlyingToken.approve(address(optionToken), type(uint256).max);
        vm.prank(Constants.WRITER1);
        underlyingToken.approve(address(optionToken), type(uint256).max);
        vm.prank(Constants.WRITER2);
        underlyingToken.approve(address(optionToken), type(uint256).max);
        vm.prank(Constants.WRITER3);
        underlyingToken.approve(address(optionToken), type(uint256).max);
        vm.prank(Constants.EXERCISER);
        underlyingToken.approve(address(optionToken), type(uint256).max);

        // approve the option token to spend the quote tokens
        vm.prank(initiator);
        quoteToken.approve(address(optionToken), type(uint256).max);
        vm.prank(Constants.EXERCISER);
        quoteToken.approve(address(optionToken), type(uint256).max);
    }
}
