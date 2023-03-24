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

    MockQuoteToken public quoteToken;
    MockUnderlyingToken public underlyingToken;
    OptionFactory public optionFactory;

    function setUp() public {
        underlyingToken = new MockUnderlyingToken();
        quoteToken = new MockQuoteToken();

        optionFactory = new OptionFactory(address(underlyingToken), address(quoteToken), _FEE);
    }

    function testCallOptionName() public {
        CloberOptionFactory.OptionParams[] memory optionParams = new CloberOptionFactory.OptionParams[](1);
        optionParams[0] = CloberOptionFactory.OptionParams(true, 1679637415, 99 * 10**17);
        address[] memory aa = optionFactory.deployOptions(optionParams);

        assertEq(ERC20(aa[0]).name(), "Fake ARB Call Options at 9.90 fUSD (exp.20230324)", "WRONG_NAME");
    }

    function testPutOptionName() public {
        CloberOptionFactory.OptionParams[] memory optionParams = new CloberOptionFactory.OptionParams[](1);
        optionParams[0] = CloberOptionFactory.OptionParams(false, 1679637415, 1234 * 10**17);
        address[] memory aa = optionFactory.deployOptions(optionParams);

        assertEq(ERC20(aa[0]).name(), "Fake ARB Put Options at 123 fUSD (exp.20230324)", "WRONG_NAME");
    }

    function testCallOptionSymbol() public {
        CloberOptionFactory.OptionParams[] memory optionParams = new CloberOptionFactory.OptionParams[](1);
        optionParams[0] = CloberOptionFactory.OptionParams(true, 1679637415, 99 * 10**17);
        address[] memory aa = optionFactory.deployOptions(optionParams);

        assertEq(ERC20(aa[0]).symbol(), "fARB-20230324-9.90-C", "WRONG_SYMBOL");
    }

    function testPutOptionSymbol() public {
        CloberOptionFactory.OptionParams[] memory optionParams = new CloberOptionFactory.OptionParams[](1);
        optionParams[0] = CloberOptionFactory.OptionParams(false, 1679637415, 1234 * 10**17);
        address[] memory aa = optionFactory.deployOptions(optionParams);

        assertEq(ERC20(aa[0]).symbol(), "fARB-20230324-123-P", "WRONG_SYMBOL");
    }
}
