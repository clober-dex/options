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

contract PutOptionWriteUnitTest is Test {
    event Write(address indexed writer, uint256 amount);

    PutOptionToken optionToken;

    MockQuoteToken quoteToken;
    MockUnderlyingToken underlyingToken;

    function setUp() public {
        (quoteToken, underlyingToken, optionToken) = (new PutOptionTokenUnitTestSetUp()).run(
            23 * 10**12, // $0.000023
            10000 // 1%
        );
    }

    function _write(
        address user,
        uint256 optionAmount,
        uint256 expectedQuoteAmount
    ) private {
        uint256 beforeOptionBalance = optionToken.balanceOf(user);
        uint256 beforeQuoteBalance = quoteToken.balanceOf(user);
        uint256 beforeCollateralBalance = optionToken.collateral(user);

        vm.expectEmit(true, false, false, true);
        emit Write(user, optionAmount);
        vm.prank(user);
        optionToken.write(optionAmount);

        assertEq(optionToken.balanceOf(user), beforeOptionBalance + optionAmount, "WRITE_OPTION_BALANCE");
        assertEq(quoteToken.balanceOf(user), beforeQuoteBalance - expectedQuoteAmount, "WRITE_QUOTE_BALANCE");
        assertEq(
            optionToken.collateral(user),
            beforeCollateralBalance + expectedQuoteAmount,
            "WRITE_COLLATERAL_BALANCE"
        );
    }

    function testWriteNormalCase() public {
        _write({
            user: Constants.WRITER1,
            optionAmount: 2000 * (10**optionToken.decimals()),
            expectedQuoteAmount: 1000 * (10**quoteToken.decimals())
        });
    }

    function testWriteRoundDownCase() public {
        _write({user: Constants.WRITER1, optionAmount: 3333333333333333333, expectedQuoteAmount: 1666667});
    }

    function testWriteUnderQuotePrecisionComplement() public {
        vm.expectRevert("INVALID_AMOUNT");
        optionToken.write(0);

        uint256 _minimumAmountToNotRevert = 2 * 10**(18 - quoteToken.decimals());
        optionToken.write(_minimumAmountToNotRevert);
    }

    function testWriteWhenOptionExpired() public {
        vm.warp(1 days + 1);
        uint256 _amount = 1000 * (10**optionToken.decimals());
        vm.expectRevert("OPTION_EXPIRED");
        optionToken.write(_amount);
    }
}
