// SPDX-License-Identifier: -
// License: https://license.clober.io/LICENSE.pdf

pragma solidity ^0.8.0;

import "../arbitrum/Arbitrum$0.5PutOption.sol";
import "../arbitrum/Arbitrum$1PutOption.sol";
import "../arbitrum/Arbitrum$2PutOption.sol";
import "../arbitrum/Arbitrum$4PutOption.sol";
import "../arbitrum/Arbitrum$8PutOption.sol";
import "../arbitrum/Arbitrum$16PutOption.sol";

contract TestNetHelper {
    struct LockedCollateral {
        uint256 $0_5;
        uint256 $1;
        uint256 $2;
        uint256 $4;
        uint256 $8;
        uint256 $16;
    }

    struct OptionTokenBalance {
        uint256 $0_5;
        uint256 $1;
        uint256 $2;
        uint256 $4;
        uint256 $8;
        uint256 $16;
    }

    struct UnderlyingTokenAllowance {
        uint256 $0_5;
        uint256 $1;
        uint256 $2;
        uint256 $4;
        uint256 $8;
        uint256 $16;
    }

    struct QuoteTokenAllowance {
        uint256 $0_5;
        uint256 $1;
        uint256 $2;
        uint256 $4;
        uint256 $8;
        uint256 $16;
    }

    address constant UNDERLYING_TOKEN = 0xd2a46071A279245b25859609C3de9305e6D5b3F2;
    address constant QUOTE_TOKEN = 0xf3F8E2d3ab08BD619A794A85626970731c4174aA;

    address constant $0_5_OPTION = 0x5D45a5ADa82ecf78021E9b4518036a3B649e5a35;
    address constant $1_OPTION = 0x0820Ed58A1f0d6FF42712a1877E368f183C94219;
    address constant $2_OPTION = 0xefa4841C3FA0bCC33987DA112f7EA3b1aC7541D9;
    address constant $4_OPTION = 0x8705373587dA69FB99181938E1463982f0Fa5b56;
    address constant $8_OPTION = 0xb28f8E47818dd44FA3d94928BE42809494FD506B;
    address constant $16_OPTION = 0x5c4871CA3EB28C1c552E5DaCF31B20BE939E156d;

    function getUserBalance(address user)
        external
        view
        returns (
            LockedCollateral memory,
            OptionTokenBalance memory,
            UnderlyingTokenAllowance memory,
            QuoteTokenAllowance memory,
            uint256 underlyingTokenBalance,
            uint256 quoteTokenBalance
        )
    {
        return (
            LockedCollateral(
                Arbitrum$0_5PutOption($0_5_OPTION).collateral(user),
                Arbitrum$1PutOption($1_OPTION).collateral(user),
                Arbitrum$2PutOption($2_OPTION).collateral(user),
                Arbitrum$4PutOption($4_OPTION).collateral(user),
                Arbitrum$8PutOption($8_OPTION).collateral(user),
                Arbitrum$16PutOption($16_OPTION).collateral(user)
            ),
            OptionTokenBalance(
                Arbitrum$0_5PutOption($0_5_OPTION).balanceOf(user),
                Arbitrum$1PutOption($1_OPTION).balanceOf(user),
                Arbitrum$2PutOption($2_OPTION).balanceOf(user),
                Arbitrum$4PutOption($4_OPTION).balanceOf(user),
                Arbitrum$8PutOption($8_OPTION).balanceOf(user),
                Arbitrum$16PutOption($16_OPTION).balanceOf(user)
            ),
            UnderlyingTokenAllowance(
                IERC20(UNDERLYING_TOKEN).allowance(user, $0_5_OPTION),
                IERC20(UNDERLYING_TOKEN).allowance(user, $1_OPTION),
                IERC20(UNDERLYING_TOKEN).allowance(user, $2_OPTION),
                IERC20(UNDERLYING_TOKEN).allowance(user, $4_OPTION),
                IERC20(UNDERLYING_TOKEN).allowance(user, $8_OPTION),
                IERC20(UNDERLYING_TOKEN).allowance(user, $16_OPTION)
            ),
            QuoteTokenAllowance(
                IERC20(QUOTE_TOKEN).allowance(user, $0_5_OPTION),
                IERC20(QUOTE_TOKEN).allowance(user, $1_OPTION),
                IERC20(QUOTE_TOKEN).allowance(user, $2_OPTION),
                IERC20(QUOTE_TOKEN).allowance(user, $4_OPTION),
                IERC20(QUOTE_TOKEN).allowance(user, $8_OPTION),
                IERC20(QUOTE_TOKEN).allowance(user, $16_OPTION)
            ),
            IERC20(UNDERLYING_TOKEN).balanceOf(user),
            IERC20(QUOTE_TOKEN).balanceOf(user)
        );
    }
}
