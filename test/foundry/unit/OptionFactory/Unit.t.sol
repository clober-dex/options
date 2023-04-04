// SPDX-License-Identifier: -
// License: https://license.clober.io/LICENSE.pdf

pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "../../mocks/MockQuoteToken.sol";
import "../../mocks/MockUnderlyingToken.sol";
import "../../../contracts/OptionFactory.sol";
import "../../../contracts/interfaces/CloberOptionFactory.sol";

contract OptionFactoryUnitTest is Test {
    uint256 private constant _FEE = 1000; // 0.1%

    MockUnderlyingToken private _underlyingToken;
    MockQuoteToken private _quoteToken;
    OptionFactory private _optionFactory;

    function setUp() public {
        _underlyingToken = new MockUnderlyingToken();
        _quoteToken = new MockQuoteToken();

        _optionFactory = new OptionFactory(address(_underlyingToken), address(_quoteToken), _FEE);
    }

    function _checkOptionInfos(
        CloberOptionToken optionToken,
        string memory name,
        string memory symbol,
        address underlyingToken,
        address quoteToken,
        uint256 expiresAt,
        uint256 exerciseFee,
        uint256 strikePrice
    ) internal {
        assertEq(IERC20Metadata(address(optionToken)).name(), name, "INVALID_NAME");
        assertEq(IERC20Metadata(address(optionToken)).symbol(), symbol, "INVALID_SYMBOL");
        assertEq(optionToken.quoteToken(), quoteToken, "INVALID_QUOTE_TOKEN");
        assertEq(optionToken.underlyingToken(), underlyingToken, "INVALID_UNDERLYING_TOKEN");
        assertEq(optionToken.expiresAt(), expiresAt, "INVALID_EXPIRE_TIMESTAMP");
        assertEq(optionToken.exerciseFee(), exerciseFee, "INVALID_EXERCISE_FEE");
        assertEq(optionToken.strikePrice(), strikePrice, "INVALID_STRIKE_PRICE");
    }

    function testCallOptionInfo() public {
        CloberOptionFactory.OptionParams[] memory optionParams = new CloberOptionFactory.OptionParams[](2);
        optionParams[0] = CloberOptionFactory.OptionParams(true, 1679637415, 99 * 10**17);
        optionParams[1] = CloberOptionFactory.OptionParams(true, 1679938736, 1345 * 10**18);

        address[] memory optionAddresses = _optionFactory.deployOptions(optionParams);

        _checkOptionInfos(
            CloberOptionToken(optionAddresses[0]),
            "Fake ARB Call Options at 9.90 fUSD (exp.20230324)",
            "fARB-20230324-9.90-C",
            address(_underlyingToken),
            address(_quoteToken),
            1679637415,
            1000,
            99 * 10**17
        );

        _checkOptionInfos(
            CloberOptionToken(optionAddresses[1]),
            "Fake ARB Call Options at 1345 fUSD (exp.20230327)",
            "fARB-20230327-1345-C",
            address(_underlyingToken),
            address(_quoteToken),
            1679938736,
            1000,
            1345 * 10**18
        );
    }

    function testPutOptionInfo() public {
        CloberOptionFactory.OptionParams[] memory optionParams = new CloberOptionFactory.OptionParams[](2);
        optionParams[0] = CloberOptionFactory.OptionParams(false, 1679637415, 99 * 10**17);
        optionParams[1] = CloberOptionFactory.OptionParams(false, 1679938736, 1345 * 10**18);

        address[] memory optionAddresses = _optionFactory.deployOptions(optionParams);

        _checkOptionInfos(
            CloberOptionToken(optionAddresses[0]),
            "Fake ARB Put Options at 9.90 fUSD (exp.20230324)",
            "fARB-20230324-9.90-P",
            address(_underlyingToken),
            address(_quoteToken),
            1679637415,
            1000,
            99 * 10**17
        );

        _checkOptionInfos(
            CloberOptionToken(optionAddresses[1]),
            "Fake ARB Put Options at 1345 fUSD (exp.20230327)",
            "fARB-20230327-1345-P",
            address(_underlyingToken),
            address(_quoteToken),
            1679938736,
            1000,
            1345 * 10**18
        );
    }
}
