// SPDX-License-Identifier: -
// License: https://license.clober.io/LICENSE.pdf

pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "../../mocks/MockPutOptionToken.sol";
import "../../mocks/MockQuoteToken.sol";
import "../../mocks/MockUnderlyingToken.sol";
import "../../../contracts/PutOptionToken.sol";

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
    uint256 constant WRITE_AMOUNT = 70 * 10**18;
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
    ) private returns (uint256 writtenAmount) {
        PutOptionToken optionToken = PutOptionToken(putOption);

        uint256 quoteAmount = (optionToken.strikePrice() * amount) / (10**18) / (10**(18 - quoteToken.decimals()));
        writtenAmount = (quoteAmount * 10**18 * 10**(18 - quoteToken.decimals())) / optionToken.strikePrice();
        quoteToken.mint(user, quoteAmount);

        uint256 beforeCollateral = optionToken.collateral(user);
        uint256 beforeOptionBalance = optionToken.balanceOf(user);
        uint256 beforeQuoteBalance = quoteToken.balanceOf(user);

        vm.prank(user);
        quoteToken.approve(putOption, quoteAmount);
        vm.prank(user);
        optionToken.write(amount);

        assertEq(optionToken.collateral(user), beforeCollateral + quoteAmount, "EXACT_COLLATERAL");
        assertEq(optionToken.balanceOf(user), beforeOptionBalance + writtenAmount, "EXACT_WRITE_AMOUNT");
        assertEq(quoteToken.balanceOf(user), beforeQuoteBalance - quoteAmount, "EXACT_QUOTE_AMOUNT");

        return writtenAmount;
    }

    function _cancel(
        address putOption,
        uint256 amount,
        address user
    ) private {
        PutOptionToken optionToken = PutOptionToken(putOption);

        uint256 quoteAmount = (optionToken.strikePrice() * amount) / (10**18) / (10**(18 - quoteToken.decimals()));

        uint256 beforeCollateral = optionToken.collateral(user);
        uint256 beforeOptionBalance = optionToken.balanceOf(user);
        uint256 beforeQuoteBalance = quoteToken.balanceOf(user);

        vm.prank(user);
        optionToken.cancel(amount);

        assertEq(optionToken.collateral(user), beforeCollateral - quoteAmount, "EXACT_COLLATERAL");
        assertEq(optionToken.balanceOf(user), beforeOptionBalance - amount, "EXACT_OPTION_AMOUNT");
        assertEq(quoteToken.balanceOf(user), beforeQuoteBalance + quoteAmount, "EXACT_QUOTE_AMOUNT");
    }

    function _exercise(
        address putOption,
        uint256 amount,
        address user
    ) private {
        PutOptionToken optionToken = PutOptionToken(putOption);

        uint256 quoteAmount = (optionToken.strikePrice() * amount) / (10**18) / (10**(18 - quoteToken.decimals()));
        uint256 exerciseAmount = (quoteAmount * 10**18 * 10**(18 - quoteToken.decimals())) / optionToken.strikePrice();
        underlyingToken.mint(user, amount);

        uint256 beforeOptionBalance = optionToken.balanceOf(user);
        uint256 beforeUnderlyingBalance = underlyingToken.balanceOf(user);
        uint256 beforeQuoteBalance = quoteToken.balanceOf(user);

        vm.prank(user);
        underlyingToken.approve(putOption, amount);
        vm.prank(user);
        optionToken.exercise(amount);

        assertEq(optionToken.balanceOf(user), beforeOptionBalance - exerciseAmount, "EXACT_OPTION_AMOUNT");
        assertEq(underlyingToken.balanceOf(user), beforeUnderlyingBalance - exerciseAmount, "EXACT_UNDERLYING_AMOUNT");
        assertEq(
            quoteToken.balanceOf(user),
            beforeQuoteBalance + quoteAmount - (quoteAmount * FEE) / 10**6,
            "EXACT_QUOTE_AMOUNT"
        );
    }

    function _claim(address putOption, address user) private {
        PutOptionToken optionToken = PutOptionToken(putOption);

        uint256 beforeCollateral = optionToken.collateral(user);
        uint256 writtenAmount = (beforeCollateral * 10**18 * 10**(18 - quoteToken.decimals())) /
            optionToken.strikePrice();
        uint256 beforeUnderlyingBalance = underlyingToken.balanceOf(user);
        uint256 beforeQuoteBalance = quoteToken.balanceOf(user);
        uint256 totalWrittenAmount = optionToken.totalSupply() + optionToken.exercisedAmount();

        uint256 claimableUnderlyingBalance = (underlyingToken.balanceOf(putOption) * writtenAmount) /
            totalWrittenAmount;
        uint256 claimableQuoteBalance = (quoteToken.balanceOf(putOption) * writtenAmount) / totalWrittenAmount;
        vm.prank(user);
        optionToken.claim();

        assertEq(
            underlyingToken.balanceOf(user),
            beforeUnderlyingBalance + claimableUnderlyingBalance,
            "TRANSFER_EXACT_AMOUNT"
        );
        assertEq(quoteToken.balanceOf(user), beforeQuoteBalance + claimableQuoteBalance, "TRANSFER_EXACT_AMOUNT");
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

    function testWriteWithValues() public {
        // Mint 1 fUSD
        quoteToken.mint(WRITER1, 10**6);
        // Approve fUSD and write 2 put options
        vm.prank(WRITER1);
        quoteToken.approve(address(put0_5OptionToken), 10**6);
        vm.prank(WRITER1);
        put0_5OptionToken.write(2 * 10**18);

        assertEq(put0_5OptionToken.collateral(WRITER1), 10**6, "EXACT_COLLATERAL");
        assertEq(put0_5OptionToken.balanceOf(WRITER1), 2 * 10**18, "EXACT_WRITE_AMOUNT");
        assertEq(quoteToken.balanceOf(WRITER1), 0, "EXACT_QUOTE_AMOUNT");
    }

    function testTokenTransfer() public {
        _write(address(put2OptionToken), WRITE_AMOUNT, WRITER1);
        _transfer(address(put2OptionToken), WRITER1, EXERCISER, (WRITE_AMOUNT * 2) / 3);
        _transferFrom(address(put2OptionToken), WRITER1, EXERCISER, WRITE_AMOUNT / 3);
    }

    function testExercise() public {
        uint256 writtenAmount;
        writtenAmount += _write(address(put0_5OptionToken), WRITE_AMOUNT / 3, WRITER1);
        writtenAmount += _write(address(put0_5OptionToken), (WRITE_AMOUNT * 2) / 3, WRITER1);
        _transfer(address(put0_5OptionToken), WRITER1, EXERCISER, writtenAmount);
        _exercise(address(put0_5OptionToken), WRITE_AMOUNT / 3, EXERCISER);
        _exercise(address(put0_5OptionToken), (WRITE_AMOUNT * 2) / 3, EXERCISER);
    }

    function testExerciseWithValues() public {
        _write(address(put0_5OptionToken), 10**18, WRITER1);
        _transfer(address(put0_5OptionToken), WRITER1, EXERCISER, 10**18);

        underlyingToken.mint(EXERCISER, 10**18);
        vm.prank(EXERCISER);
        underlyingToken.approve(address(put0_5OptionToken), 10**18);
        vm.prank(EXERCISER);
        put0_5OptionToken.exercise(10**18);

        assertEq(put0_5OptionToken.collateral(WRITER1), 5 * 10**5, "EXACT_COLLATERAL");
        assertEq(put0_5OptionToken.balanceOf(EXERCISER), 0, "EXACT_OPTION_AMOUNT");
        assertEq(quoteToken.balanceOf(EXERCISER), 5 * 10**5 - 5 * 10**2, "EXACT_QUOTE_AMOUNT");
        assertEq(underlyingToken.balanceOf(EXERCISER), 0, "EXACT_UNDERLYING_AMOUNT");
    }

    function testClaim() public {
        uint256 writtenAmount1 = _write(address(put0_5OptionToken), WRITE_AMOUNT / 3, WRITER1);
        uint256 writtenAmount2 = _write(address(put0_5OptionToken), WRITE_AMOUNT / 6, WRITER2);
        uint256 writtenAmount3 = _write(address(put0_5OptionToken), WRITE_AMOUNT / 9, WRITER3);

        _transfer(address(put0_5OptionToken), WRITER1, EXERCISER, writtenAmount1);
        _transfer(address(put0_5OptionToken), WRITER2, EXERCISER, writtenAmount2);
        _transfer(address(put0_5OptionToken), WRITER3, EXERCISER, writtenAmount3);

        _exercise(address(put0_5OptionToken), (WRITE_AMOUNT * 5) / 11, EXERCISER);

        vm.warp(1 days + 1);

        _claim(address(put0_5OptionToken), WRITER1);
    }

    function testClaimWithValues() public {
        uint256 amount1 = 1 * 10**18;
        uint256 amount2 = 2 * 10**18;
        uint256 amount3 = 3 * 10**18;
        _write(address(put0_5OptionToken), amount1, WRITER1);
        _write(address(put0_5OptionToken), amount2, WRITER2);
        _write(address(put0_5OptionToken), amount3, WRITER3);
        _transfer(address(put0_5OptionToken), WRITER1, EXERCISER, amount1);
        _transfer(address(put0_5OptionToken), WRITER2, EXERCISER, amount2);
        _transfer(address(put0_5OptionToken), WRITER3, EXERCISER, amount3);
        // 1/3 of the options are exercised
        _exercise(address(put0_5OptionToken), 2 * 10**18, EXERCISER);

        vm.warp(1 days + 1);

        uint256 collateral = put0_5OptionToken.collateral(WRITER1);
        vm.prank(WRITER1);
        put0_5OptionToken.claim();

        assertEq(put0_5OptionToken.collateral(WRITER1), 0, "EXACT_COLLATERAL_AMOUNT");
        assertEq(underlyingToken.balanceOf(WRITER1), (amount1) / 3, "EXACT_COLLATERAL_AMOUNT");
        assertEq(quoteToken.balanceOf(WRITER1), (collateral * 2) / 3, "EXACT_COLLATERAL_AMOUNT");

        collateral = put0_5OptionToken.collateral(WRITER2);
        vm.prank(WRITER2);
        put0_5OptionToken.claim();

        assertEq(put0_5OptionToken.collateral(WRITER2), 0, "EXACT_COLLATERAL_AMOUNT");
        assertEq(underlyingToken.balanceOf(WRITER2), (amount2) / 3, "EXACT_COLLATERAL_AMOUNT");
        assertEq(quoteToken.balanceOf(WRITER2), (collateral * 2) / 3, "EXACT_COLLATERAL_AMOUNT");

        collateral = put0_5OptionToken.collateral(WRITER3);
        vm.prank(WRITER3);
        put0_5OptionToken.claim();

        assertEq(put0_5OptionToken.collateral(WRITER3), 0, "EXACT_COLLATERAL_AMOUNT");
        assertEq(underlyingToken.balanceOf(WRITER3), (amount3) / 3, "EXACT_COLLATERAL_AMOUNT");
        assertEq(quoteToken.balanceOf(WRITER3), (collateral * 2) / 3, "EXACT_COLLATERAL_AMOUNT");
    }

    function testCancel() public {
        _write(address(put0_5OptionToken), WRITE_AMOUNT / 3, WRITER1);
        _write(address(put0_5OptionToken), (WRITE_AMOUNT * 2) / 3, WRITER1);
        _cancel(address(put0_5OptionToken), WRITE_AMOUNT / 3, WRITER1);
        _cancel(address(put0_5OptionToken), (WRITE_AMOUNT * 2) / 3, WRITER1);
    }
}
