// SPDX-License-Identifier: -
// License: https://license.clober.io/LICENSE.pdf

pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "../../../mocks/MockQuoteToken.sol";
import "../../../mocks/MockUnderlyingToken.sol";
import "../../../mocks/MockPutOptionToken.sol";
import "../Constants.sol";

contract PutOptionTokenUnitTestSetUp is Test {
    function run(uint256 strikePrice, uint256 exerciseFee)
        external
        returns (
            MockQuoteToken quoteToken,
            MockUnderlyingToken underlyingToken,
            MockPutOptionToken optionToken
        )
    {
        quoteToken = new MockQuoteToken();
        underlyingToken = new MockUnderlyingToken();

        // mint some tokens to the writers
        quoteToken.mint(address(this), 10000000 * (10**quoteToken.decimals()));
        quoteToken.mint(Constants.WRITER1, 10000000 * (10**quoteToken.decimals()));
        quoteToken.mint(Constants.WRITER2, 10000000 * (10**quoteToken.decimals()));
        quoteToken.mint(Constants.WRITER3, 10000000 * (10**quoteToken.decimals()));
        quoteToken.mint(Constants.EXERCISER, 10000000 * (10**quoteToken.decimals()));

        underlyingToken.mint(address(this), 10000000 * (10**underlyingToken.decimals()));
        underlyingToken.mint(Constants.EXERCISER, 10000000 * (10**underlyingToken.decimals()));

        optionToken = new MockPutOptionToken(
            address(underlyingToken),
            address(quoteToken),
            strikePrice,
            Constants.EXPIRES_AT,
            exerciseFee
        );

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
}
