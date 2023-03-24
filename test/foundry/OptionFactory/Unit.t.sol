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

    function testName() public {
        CloberOptionFactory.OptionParams[] memory optionParams = new CloberOptionFactory.OptionParams[](1);
        optionParams[0] = CloberOptionFactory.OptionParams(true, 1679637415, 1600 * 10**18);
        address[] memory aa = optionFactory.deployOptions(optionParams);

        console.log(ERC20(aa[0]).name());
    }

    function testSymbol() public {
        CloberOptionFactory.OptionParams[] memory optionParams = new CloberOptionFactory.OptionParams[](1);
        optionParams[0] = CloberOptionFactory.OptionParams(true, 1679637415, 1600 * 10**18);
        address[] memory aa = optionFactory.deployOptions(optionParams);

        console.log(ERC20(aa[0]).symbol());
    }
}
