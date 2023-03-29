//// SPDX-License-Identifier: -
//// License: https://license.clober.io/LICENSE.pdf
//
//pragma solidity ^0.8.0;
//
//import "forge-std/Test.sol";
//
//import "../../mocks/MockCallOptionToken.sol";
//import "../../mocks/MockQuoteToken.sol";
//import "../../mocks/MockUnderlyingToken.sol";
//import "../../../contracts/PutOptionToken.sol";
//import "../Constants.sol";
//
//contract CallOptionsUnitTest is Test {
//    MockCallOptionToken[] callOptionTokens;
//
//    function setUp() public {
//        quoteToken = new MockQuoteToken();
//        underlyingToken = new MockUnderlyingToken();
//
//        address quote = address(quoteToken);
//        address underlying = address(underlyingToken);
//
//        callOptionTokens.push(new MockCallOptionToken(underlying, quote, 5 * 10**17, 1 days, FEE));
//    }
//
//    function testViewFunction() public {
//        assertEq(put2OptionToken.name(), "Mock Put Option", "EXACT_NAME");
//        assertEq(put2OptionToken.symbol(), "M-P", "EXACT_SYMBOL");
//        assertEq(put2OptionToken.decimals(), 18, "EXACT_DECIMALS");
//        assertEq(put2OptionToken.quoteToken(), address(quoteToken), "EXACT_QUOTE_TOKEN");
//        assertEq(put2OptionToken.underlyingToken(), address(underlyingToken), "EXACT_UNDERLYING_TOKEN");
//        assertEq(put2OptionToken.strikePrice(), 2 * 10**18, "EXACT_STRIKE_PRICE");
//    }
//
//    function _write(
//        address putOption,
//        uint256 amount,
//        address user
//    ) private returns (uint256 writtenAmount) {
//        PutOptionToken optionToken = PutOptionToken(putOption);
//
//        uint256 quoteAmount = (optionToken.strikePrice() * amount) / (10**18) / (10**(18 - quoteToken.decimals()));
//        writtenAmount = (quoteAmount * 10**18 * 10**(18 - quoteToken.decimals())) / optionToken.strikePrice();
//        quoteToken.mint(user, quoteAmount);
//
//        uint256 beforeCollateral = optionToken.collateral(user);
//        uint256 beforeOptionBalance = optionToken.balanceOf(user);
//        uint256 beforeQuoteBalance = quoteToken.balanceOf(user);
//
//        vm.prank(user);
//        quoteToken.approve(putOption, quoteAmount);
//        vm.prank(user);
//        optionToken.write(amount);
//
//        assertEq(optionToken.collateral(user), beforeCollateral + quoteAmount, "EXACT_COLLATERAL");
//        assertEq(optionToken.balanceOf(user), beforeOptionBalance + writtenAmount, "EXACT_WRITE_AMOUNT");
//        assertEq(quoteToken.balanceOf(user), beforeQuoteBalance - quoteAmount, "EXACT_QUOTE_AMOUNT");
//
//        return writtenAmount;
//    }
//
//    function _cancel(
//        address putOption,
//        uint256 amount,
//        address user
//    ) private {
//        PutOptionToken optionToken = PutOptionToken(putOption);
//
//        uint256 quoteAmount = (optionToken.strikePrice() * amount) / (10**18) / (10**(18 - quoteToken.decimals()));
//
//        uint256 beforeCollateral = optionToken.collateral(user);
//        uint256 beforeOptionBalance = optionToken.balanceOf(user);
//        uint256 beforeQuoteBalance = quoteToken.balanceOf(user);
//
//        vm.prank(user);
//        optionToken.cancel(amount);
//
//        assertEq(optionToken.collateral(user), beforeCollateral - quoteAmount, "EXACT_COLLATERAL");
//        assertEq(optionToken.balanceOf(user), beforeOptionBalance - amount, "EXACT_OPTION_AMOUNT");
//        assertEq(quoteToken.balanceOf(user), beforeQuoteBalance + quoteAmount, "EXACT_QUOTE_AMOUNT");
//    }
//
//    function _exercise(
//        address putOption,
//        uint256 amount,
//        address user
//    ) private {
//        PutOptionToken optionToken = PutOptionToken(putOption);
//
//        uint256 quoteAmount = (optionToken.strikePrice() * amount) / (10**18) / (10**(18 - quoteToken.decimals()));
//        uint256 exerciseAmount = (quoteAmount * 10**18 * 10**(18 - quoteToken.decimals())) / optionToken.strikePrice();
//        underlyingToken.mint(user, amount);
//
//        uint256 beforeOptionBalance = optionToken.balanceOf(user);
//        uint256 beforeUnderlyingBalance = underlyingToken.balanceOf(user);
//        uint256 beforeQuoteBalance = quoteToken.balanceOf(user);
//
//        vm.prank(user);
//        underlyingToken.approve(putOption, amount);
//        vm.prank(user);
//        optionToken.exercise(amount);
//
//        assertEq(optionToken.balanceOf(user), beforeOptionBalance - exerciseAmount, "EXACT_OPTION_AMOUNT");
//        assertEq(underlyingToken.balanceOf(user), beforeUnderlyingBalance - exerciseAmount, "EXACT_UNDERLYING_AMOUNT");
//        assertEq(
//            quoteToken.balanceOf(user),
//            beforeQuoteBalance + quoteAmount - (quoteAmount * FEE) / 10**6,
//            "EXACT_QUOTE_AMOUNT"
//        );
//    }
//
//    function _claim(address putOption, address user) private {
//        PutOptionToken optionToken = PutOptionToken(putOption);
//
//        uint256 beforeCollateral = optionToken.collateral(user);
//        uint256 writtenAmount = (beforeCollateral * 10**18 * 10**(18 - quoteToken.decimals())) /
//            optionToken.strikePrice();
//        uint256 beforeUnderlyingBalance = underlyingToken.balanceOf(user);
//        uint256 beforeQuoteBalance = quoteToken.balanceOf(user);
//        uint256 totalWrittenAmount = optionToken.totalSupply() + optionToken.exercisedAmount();
//
//        uint256 claimableUnderlyingBalance = (underlyingToken.balanceOf(putOption) * writtenAmount) /
//            totalWrittenAmount;
//        uint256 claimableQuoteBalance = (quoteToken.balanceOf(putOption) * writtenAmount) / totalWrittenAmount;
//        vm.prank(user);
//        optionToken.claim();
//
//        assertEq(
//            underlyingToken.balanceOf(user),
//            beforeUnderlyingBalance + claimableUnderlyingBalance,
//            "TRANSFER_EXACT_AMOUNT"
//        );
//        assertEq(quoteToken.balanceOf(user), beforeQuoteBalance + claimableQuoteBalance, "TRANSFER_EXACT_AMOUNT");
//    }
//
//    function _transfer(
//        address putOption,
//        address from,
//        address to,
//        uint256 amount
//    ) private {
//        PutOptionToken optionToken = PutOptionToken(putOption);
//        uint256 formBeforeBalance = optionToken.balanceOf(from);
//        uint256 toBeforeBalance = optionToken.balanceOf(to);
//        vm.prank(from);
//        optionToken.transfer(to, amount);
//        assertEq(optionToken.balanceOf(from), formBeforeBalance - amount, "TRANSFER_EXACT_AMOUNT");
//        assertEq(optionToken.balanceOf(to), toBeforeBalance + amount, "TRANSFER_EXACT_AMOUNT");
//    }
//
//    function _transferFrom(
//        address putOption,
//        address from,
//        address to,
//        uint256 amount
//    ) private {
//        PutOptionToken optionToken = PutOptionToken(putOption);
//        uint256 formBeforeBalance = optionToken.balanceOf(from);
//        uint256 toBeforeBalance = optionToken.balanceOf(to);
//        vm.prank(from);
//        optionToken.approve(to, amount);
//        vm.prank(to);
//        optionToken.transferFrom(from, to, amount);
//        assertEq(optionToken.balanceOf(WRITER1), formBeforeBalance - amount, "TRANSFER_EXACT_AMOUNT");
//        assertEq(optionToken.balanceOf(EXERCISER), toBeforeBalance + amount, "TRANSFER_EXACT_AMOUNT");
//    }
//
//    function testWrite() public {
//        _write(address(put0_5OptionToken), WRITE_AMOUNT, WRITER1);
//        _write(address(put1OptionToken), WRITE_AMOUNT, WRITER1);
//        _write(address(put2OptionToken), WRITE_AMOUNT, WRITER1);
//        _write(address(put4OptionToken), WRITE_AMOUNT, WRITER1);
//        _write(address(put8OptionToken), WRITE_AMOUNT, WRITER1);
//        _write(address(put16OptionToken), WRITE_AMOUNT, WRITER1);
//        _write(address(put0_5OptionToken), WRITE_AMOUNT, WRITER1);
//        _write(address(put1OptionToken), WRITE_AMOUNT, WRITER1);
//        _write(address(put2OptionToken), WRITE_AMOUNT, WRITER1);
//        _write(address(put4OptionToken), WRITE_AMOUNT, WRITER1);
//        _write(address(put8OptionToken), WRITE_AMOUNT, WRITER1);
//        _write(address(put16OptionToken), WRITE_AMOUNT, WRITER1);
//    }
//
//    function testWriteWithValues() public {
//        // Mint 1 fUSD
//        quoteToken.mint(WRITER1, 10**6);
//        // Approve fUSD and write 2 put options
//        vm.prank(WRITER1);
//        quoteToken.approve(address(put0_5OptionToken), 10**6);
//        vm.prank(WRITER1);
//        put0_5OptionToken.write(2 * 10**18);
//
//        assertEq(put0_5OptionToken.collateral(WRITER1), 10**6, "EXACT_COLLATERAL");
//        assertEq(put0_5OptionToken.balanceOf(WRITER1), 2 * 10**18, "EXACT_WRITE_AMOUNT");
//        assertEq(quoteToken.balanceOf(WRITER1), 0, "EXACT_QUOTE_AMOUNT");
//    }
//
//    function testTokenTransfer() public {
//        _write(address(put2OptionToken), WRITE_AMOUNT, WRITER1);
//        _transfer(address(put2OptionToken), WRITER1, EXERCISER, (WRITE_AMOUNT * 2) / 3);
//        _transferFrom(address(put2OptionToken), WRITER1, EXERCISER, WRITE_AMOUNT / 3);
//    }
//
//    function testExercise() public {
//        uint256 writtenAmount;
//        writtenAmount += _write(address(put0_5OptionToken), WRITE_AMOUNT / 3, WRITER1);
//        writtenAmount += _write(address(put0_5OptionToken), (WRITE_AMOUNT * 2) / 3, WRITER1);
//        _transfer(address(put0_5OptionToken), WRITER1, EXERCISER, writtenAmount);
//        _exercise(address(put0_5OptionToken), WRITE_AMOUNT / 3, EXERCISER);
//        _exercise(address(put0_5OptionToken), (WRITE_AMOUNT * 2) / 3, EXERCISER);
//    }
//
//    function testExerciseWithValues() public {
//        _write(address(put0_5OptionToken), 10**18, WRITER1);
//        _transfer(address(put0_5OptionToken), WRITER1, EXERCISER, 10**18);
//
//        underlyingToken.mint(EXERCISER, 10**18);
//        vm.prank(EXERCISER);
//        underlyingToken.approve(address(put0_5OptionToken), 10**18);
//        vm.prank(EXERCISER);
//        put0_5OptionToken.exercise(10**18);
//
//        assertEq(put0_5OptionToken.collateral(WRITER1), 5 * 10**5, "EXACT_COLLATERAL");
//        assertEq(put0_5OptionToken.balanceOf(EXERCISER), 0, "EXACT_OPTION_AMOUNT");
//        assertEq(quoteToken.balanceOf(EXERCISER), 5 * 10**5 - 5 * 10**2, "EXACT_QUOTE_AMOUNT");
//        assertEq(underlyingToken.balanceOf(EXERCISER), 0, "EXACT_UNDERLYING_AMOUNT");
//    }
//
//    function testClaimWithValues() public {
//        uint256 amount1 = 1 * 10**18;
//        uint256 amount2 = 2 * 10**18;
//        uint256 amount3 = 3 * 10**18;
//        _write(address(put0_5OptionToken), amount1, WRITER1);
//        _write(address(put0_5OptionToken), amount2, WRITER2);
//        _write(address(put0_5OptionToken), amount3, WRITER3);
//        _transfer(address(put0_5OptionToken), WRITER1, EXERCISER, amount1);
//        _transfer(address(put0_5OptionToken), WRITER2, EXERCISER, amount2);
//        _transfer(address(put0_5OptionToken), WRITER3, EXERCISER, amount3);
//        // 1/3 of the options are exercised
//        _exercise(address(put0_5OptionToken), 2 * 10**18, EXERCISER);
//
//        vm.warp(1 days + 1);
//
//        uint256 collateral = put0_5OptionToken.collateral(WRITER1);
//        vm.prank(WRITER1);
//        put0_5OptionToken.claim();
//
//        assertEq(put0_5OptionToken.collateral(WRITER1), 0, "EXACT_COLLATERAL_AMOUNT");
//        assertEq(underlyingToken.balanceOf(WRITER1), (amount1) / 3, "EXACT_UNDERLYING_AMOUNT");
//        assertEq(quoteToken.balanceOf(WRITER1), (collateral * 2) / 3, "EXACT_QUOTE_AMOUNT");
//
//        collateral = put0_5OptionToken.collateral(WRITER2);
//        vm.prank(WRITER2);
//        put0_5OptionToken.claim();
//
//        assertEq(put0_5OptionToken.collateral(WRITER2), 0, "EXACT_COLLATERAL_AMOUNT");
//        assertEq(underlyingToken.balanceOf(WRITER2), (amount2) / 3, "EXACT_UNDERLYING_AMOUNT");
//        assertEq(quoteToken.balanceOf(WRITER2), (collateral * 2) / 3, "EXACT_QUOTE_AMOUNT");
//
//        collateral = put0_5OptionToken.collateral(WRITER3);
//        vm.prank(WRITER3);
//        put0_5OptionToken.claim();
//
//        assertEq(put0_5OptionToken.collateral(WRITER3), 0, "EXACT_COLLATERAL_AMOUNT");
//        assertEq(underlyingToken.balanceOf(WRITER3), (amount3) / 3, "EXACT_UNDERLYING_AMOUNT");
//        assertEq(quoteToken.balanceOf(WRITER3), (collateral * 2) / 3, "EXACT_QUOTE_AMOUNT");
//    }
//
//    function testCancelWithValues() public {
//        _write(address(put0_5OptionToken), 1 * 10**18, WRITER1);
//        assertEq(quoteToken.balanceOf(WRITER1), 0, "EXACT_QUOTE_AMOUNT");
//        assertEq(put0_5OptionToken.balanceOf(WRITER1), 1 * 10**18, "EXACT_OPTION_AMOUNT");
//        assertEq(put0_5OptionToken.collateral(WRITER1), 5 * 10**5, "EXACT_COLLATERAL_AMOUNT");
//
//        _write(address(put0_5OptionToken), 2 * 10**18, WRITER2);
//        assertEq(quoteToken.balanceOf(WRITER2), 0, "EXACT_QUOTE_AMOUNT");
//        assertEq(put0_5OptionToken.balanceOf(WRITER2), 2 * 10**18, "EXACT_OPTION_AMOUNT");
//        assertEq(put0_5OptionToken.collateral(WRITER2), 10**6, "EXACT_COLLATERAL_AMOUNT");
//
//        _cancel(address(put0_5OptionToken), 3 * 10**17, WRITER1);
//        assertEq(quoteToken.balanceOf(WRITER1), 15 * 10**4, "EXACT_QUOTE_AMOUNT");
//        assertEq(put0_5OptionToken.balanceOf(WRITER1), 7 * 10**17, "EXACT_OPTION_AMOUNT");
//        assertEq(put0_5OptionToken.collateral(WRITER1), 35 * 10**4, "EXACT_COLLATERAL_AMOUNT");
//
//        _cancel(address(put0_5OptionToken), 2 * 10**18, WRITER2);
//        assertEq(quoteToken.balanceOf(WRITER2), 10**6, "EXACT_QUOTE_AMOUNT");
//        assertEq(put0_5OptionToken.balanceOf(WRITER2), 0, "EXACT_OPTION_AMOUNT");
//        assertEq(put0_5OptionToken.collateral(WRITER2), 0, "EXACT_COLLATERAL_AMOUNT");
//    }
//
//    function testCollectFee() public {
//        _write(address(put1OptionToken), 10**18, WRITER1);
//        _transfer(address(put1OptionToken), WRITER1, EXERCISER, 10**18);
//
//        underlyingToken.mint(EXERCISER, 10**18);
//        vm.prank(EXERCISER);
//        underlyingToken.approve(address(put1OptionToken), 10**18);
//        vm.prank(EXERCISER);
//        put1OptionToken.exercise(10**18);
//
//        uint256 ownerQuoteBalance = quoteToken.balanceOf(put1OptionToken.owner());
//
//        vm.warp(1 days + 1);
//
//        put1OptionToken.collectFee();
//        uint256 collectedFee = quoteToken.balanceOf(put1OptionToken.owner()) - ownerQuoteBalance;
//
//        assertEq(collectedFee, 1000, "Collect fee");
//    }
//}
