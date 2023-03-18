// SPDX-License-Identifier: -
// License: https://license.clober.io/LICENSE.pdf

pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "./mocks/MockPutOptionToken.sol";
import "./mocks/MockQuoteToken.sol";
import "./mocks/MockUnderlyingToken.sol";

contract PutOptionsUnitTest is Test {
    MockPutOptionToken put0_5OptionToken;
    MockPutOptionToken put1OptionToken;
    MockPutOptionToken put2OptionToken;
    MockPutOptionToken put4OptionToken;
    MockPutOptionToken put8OptionToken;
    MockPutOptionToken put16OptionToken;

    MockQuoteToken quoteToken;
    MockUnderlyingToken underlyingToken;

    address constant WRITER1 = address(1);
    address constant WRITER2 = address(2);
    address constant WRITER3 = address(3);
    address constant EXERCISER = address(4);
    uint256 constant WRITE_AMOUNT = 90 * 10**18;
    uint256 FEE = 1000; // 0.1%

    function setUp() public {
        quoteToken = new MockQuoteToken();
        underlyingToken = new MockUnderlyingToken();

        address quote = address(quoteToken);
        address underlying = address(underlyingToken);

        put0_5OptionToken = new MockPutOptionToken(underlying, quote, 5 * 10**17, 1 days, FEE);
        put1OptionToken = new MockPutOptionToken(underlying, quote, 10**18, 1 days, FEE);
        put2OptionToken = new MockPutOptionToken(underlying, quote, 2 * 10**18, 1 days, FEE);
        put4OptionToken = new MockPutOptionToken(underlying, quote, 4 * 10**18, 1 days, FEE);
        put8OptionToken = new MockPutOptionToken(underlying, quote, 8 * 10**18, 1 days, FEE);
        put16OptionToken = new MockPutOptionToken(underlying, quote, 16 * 10**18, 1 days, FEE);
    }

    function testViewFunction() public {
        assertEq(put2OptionToken.name(), "Mock Put Option", "EXACT_NAME");
        assertEq(put2OptionToken.symbol(), "M-P", "EXACT_SYMBOL");
        assertEq(put2OptionToken.decimals(), 18, "EXACT_DECIMALS");
        assertEq(put2OptionToken.quoteToken(), address(quoteToken), "EXACT_QUOTE_TOKEN");
        assertEq(put2OptionToken.underlyingToken(), address(underlyingToken), "EXACT_UNDERLYING_TOKEN");
        assertEq(put2OptionToken.strikePrice(), 2 * 10**18, "EXACT_STRIKE_PRICE");
    }

    function _write(
        address putOption,
        uint256 amount,
        address user
    ) private {
        PutOptionToken optionToken = PutOptionToken(putOption);

        uint256 quoteAmount = (optionToken.strikePrice() * amount) / (10**underlyingToken.decimals());
        quoteToken.mint(user, quoteAmount);

        uint256 beforeCollateral = optionToken.collateral(user);
        uint256 beforeOptionBalance = optionToken.balanceOf(user);
        uint256 beforeQuoteBalance = quoteToken.balanceOf(user);

        vm.prank(WRITER1);
        quoteToken.approve(putOption, quoteAmount);
        vm.prank(WRITER1);
        optionToken.write(amount);

        assertEq(optionToken.collateral(user), beforeCollateral + quoteAmount, "EXACT_COLLATERAL");
        assertEq(optionToken.balanceOf(user), beforeOptionBalance + amount, "EXACT_WRITE_AMOUNT");
        assertEq(quoteToken.balanceOf(user), beforeQuoteBalance - quoteAmount, "EXACT_QUOTE_AMOUNT");
    }

    function _exercise(
        address putOption,
        uint256 amount,
        address user
    ) private {
        PutOptionToken optionToken = PutOptionToken(putOption);

        uint256 quoteAmount = (optionToken.strikePrice() * amount) / (10**underlyingToken.decimals());
        underlyingToken.mint(user, amount);

        uint256 beforeOptionBalance = optionToken.balanceOf(user);
        uint256 beforeUnderlyingBalance = underlyingToken.balanceOf(user);
        uint256 beforeQuoteBalance = quoteToken.balanceOf(user);

        vm.prank(EXERCISER);
        underlyingToken.approve(putOption, amount);
        optionToken.exercise(amount);

        assertEq(underlyingToken.balanceOf(user), beforeUnderlyingBalance - amount, "EXACT_WRITE_AMOUNT");
        assertEq(quoteToken.balanceOf(user), beforeQuoteBalance + quoteAmount, "EXACT_QUOTE_AMOUNT");
    }

    function _transfer(
        address putOption,
        address from,
        address to,
        uint256 amount
    ) private {
        PutOptionToken optionToken = PutOptionToken(putOption);
        uint256 formBeforeBalance = optionToken.balanceOf(from);
        uint256 toBeforeBalance = optionToken.balanceOf(to);
        vm.prank(from);
        optionToken.transfer(to, amount);
        assertEq(optionToken.balanceOf(from), formBeforeBalance - amount, "TRANSFER_EXACT_AMOUNT");
        assertEq(optionToken.balanceOf(to), toBeforeBalance + amount, "TRANSFER_EXACT_AMOUNT");
    }

    function _transferFrom(
        address putOption,
        address from,
        address to,
        uint256 amount
    ) private {
        PutOptionToken optionToken = PutOptionToken(putOption);
        uint256 formBeforeBalance = optionToken.balanceOf(from);
        uint256 toBeforeBalance = optionToken.balanceOf(to);
        vm.prank(from);
        optionToken.approve(to, amount);
        vm.prank(to);
        optionToken.transferFrom(from, to, amount);
        assertEq(optionToken.balanceOf(WRITER1), formBeforeBalance - amount, "TRANSFER_EXACT_AMOUNT");
        assertEq(optionToken.balanceOf(EXERCISER), toBeforeBalance + amount, "TRANSFER_EXACT_AMOUNT");
    }

    function testWrite() public {
        _write(address(put0_5OptionToken), WRITE_AMOUNT, WRITER1);
        _write(address(put1OptionToken), WRITE_AMOUNT, WRITER1);
        _write(address(put2OptionToken), WRITE_AMOUNT, WRITER1);
        _write(address(put4OptionToken), WRITE_AMOUNT, WRITER1);
        _write(address(put8OptionToken), WRITE_AMOUNT, WRITER1);
        _write(address(put16OptionToken), WRITE_AMOUNT, WRITER1);
        _write(address(put0_5OptionToken), WRITE_AMOUNT, WRITER1);
        _write(address(put1OptionToken), WRITE_AMOUNT, WRITER1);
        _write(address(put2OptionToken), WRITE_AMOUNT, WRITER1);
        _write(address(put4OptionToken), WRITE_AMOUNT, WRITER1);
        _write(address(put8OptionToken), WRITE_AMOUNT, WRITER1);
        _write(address(put16OptionToken), WRITE_AMOUNT, WRITER1);
    }

    function testTokenTransfer() public {
        _write(address(put2OptionToken), WRITE_AMOUNT, WRITER1);
        _transfer(address(put2OptionToken), WRITER1, EXERCISER, WRITE_AMOUNT / 2);
        _transferFrom(address(put2OptionToken), WRITER1, EXERCISER, WRITE_AMOUNT / 2);
    }

    function testExercise() public {
        _write(address(put0_5OptionToken), WRITE_AMOUNT, WRITER1);
        _transfer(address(put0_5OptionToken), WRITER1, EXERCISER, WRITE_AMOUNT);
        _exercise(address(put0_5OptionToken), WRITE_AMOUNT, EXERCISER);
    }

    function testClaim() public {}

    function testCancel() public {}
}
