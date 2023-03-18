// SPDX-License-Identifier: -
// License: https://license.clober.io/LICENSE.pdf

pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../../../contracts/mock/MockUnderlyingToken.sol";
import "../../../contracts/mock/MockQuoteToken.sol";
import "../../../contracts/mock/MockPutOption.sol";

contract PutOptionsUnitTest is Test {
    MockPutOption putOptions;
    MockQuoteToken quoteToken;
    MockUnderlyingToken underlyingToken;

    address constant MINTER = address(1);
    address constant EXERCISER = address(2);
    uint256 constant MINT_AMOUNT = 90 * 10**18;
    uint256 STRIKE_PRICE = 2 * 10**6;
    uint256 FEE = 10000;

    function setUp() public {
        quoteToken = new MockQuoteToken();
        underlyingToken = new MockUnderlyingToken();

        putOptions = new MockPutOption(
            address(underlyingToken),
            address(quoteToken),
            STRIKE_PRICE,
            1 days,
            FEE // 1%
        );
    }

    function testViewFunction() public {
        assertEq(putOptions.name(), "Mock Put Option", "EXACT_NAME");
        assertEq(putOptions.symbol(), "M-P", "EXACT_STMBOL");
        assertEq(putOptions.decimals(), 18, "EXACT_DECIMALS");
        assertEq(putOptions.quoteToken(), address(quoteToken), "EXACT_QUOTE_TOKEN");
        assertEq(putOptions.underlyingToken(), address(underlyingToken), "EXACT_UNDERLYING_TOKEN");
        assertEq(putOptions.strikePrice(), STRIKE_PRICE, "EXACT_STRIKE_PRICE");
    }

    function _write(uint256 amount, address user) private {
        uint256 quoteAmount = (putOptions.strikePrice() * amount) / (10**underlyingToken.decimals());
        quoteToken.mint(user, quoteAmount);

        uint256 beforeCollateral = putOptions.collateral(user);
        uint256 beforeOptionBalance = putOptions.balanceOf(user);
        uint256 beforeQuoteBalance = quoteToken.balanceOf(user);
        vm.prank(MINTER);
        quoteToken.approve(address(putOptions), quoteAmount);
        vm.prank(MINTER);
        putOptions.write(amount);

        assertEq(putOptions.collateral(user), beforeCollateral + quoteAmount, "EXACT_COLLATERAL");
        assertEq(putOptions.balanceOf(user), beforeOptionBalance + amount, "EXACT_WRITE_AMOUNT");
        assertEq(quoteToken.balanceOf(user), beforeQuoteBalance - quoteAmount, "EXACT_QUOTE_AMOUNT");
    }

    function _exercise(uint256 amount, address user) private {
        uint256 beforeOptionBalance = putOptions.balanceOf(user);
        uint256 beforeUnderlyingBalance = underlyingToken.balanceOf(user);
        uint256 beforeQuoteBalance = quoteToken.balanceOf(user);

        if (beforeOptionBalance < amount) {
            vm.expectRevert(stdError.arithmeticError);
            vm.prank(user);
        } else {}
        vm.prank(MINTER);
        quoteToken.approve(address(putOptions), quoteAmount);
        vm.prank(MINTER);
        putOptions.write(amount);

        assertEq(putOptions.collateral(user), beforeCollateral + quoteAmount, "EXACT_COLLATERAL");
        assertEq(putOptions.balanceOf(user), beforeOptionBalance + amount, "EXACT_WRITE_AMOUNT");
        assertEq(quoteToken.balanceOf(user), beforeQuoteBalance - quoteAmount, "EXACT_QUOTE_AMOUNT");
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        uint256 formBeforeBalance = putOptions.balanceOf(from);
        uint256 toBeforeBalance = putOptions.balanceOf(to);
        vm.prank(from);
        putOptions.transfer(to, amount);
        assertEq(putOptions.balanceOf(from), formBeforeBalance - amount, "TRANSFER_EXACT_AMOUNT");
        assertEq(putOptions.balanceOf(to), toBeforeBalance + amount, "TRANSFER_EXACT_AMOUNT");
    }

    function _transferFrom(
        address from,
        address to,
        uint256 amount
    ) private {
        uint256 formBeforeBalance = putOptions.balanceOf(from);
        uint256 toBeforeBalance = putOptions.balanceOf(to);
        vm.prank(from);
        putOptions.approve(to, amount);
        vm.prank(to);
        putOptions.transferFrom(from, to, amount);
        assertEq(putOptions.balanceOf(MINTER), formBeforeBalance - amount, "TRANSFER_EXACT_AMOUNT");
        assertEq(putOptions.balanceOf(EXERCISER), toBeforeBalance + amount, "TRANSFER_EXACT_AMOUNT");
    }

    function testWrite() public {
        _write(MINT_AMOUNT, MINTER);
    }

    function testTokenTransfer() public {
        _write(MINT_AMOUNT, MINTER);
        _transfer(MINTER, EXERCISER, MINT_AMOUNT / 2);
        _transferFrom(MINTER, EXERCISER, MINT_AMOUNT / 2);
    }

    function testExercise() public {
        vm.warp(90000);
    }

    function testRedeem() public {}

    function testRepay() public {}
}
