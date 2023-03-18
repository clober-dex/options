// SPDX-License-Identifier: -
// License: https://license.clober.io/LICENSE.pdf

pragma solidity ^0.8.0;

import "../arbitrum/Arbitrum$0.5PutOption.sol";
import "../arbitrum/Arbitrum$1PutOption.sol";
import "../arbitrum/Arbitrum$2PutOption.sol";
import "../arbitrum/Arbitrum$4PutOption.sol";
import "../arbitrum/Arbitrum$8PutOption.sol";
import "../arbitrum/Arbitrum$16PutOption.sol";

contract OptionViewer {
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

    address immutable underlyingToken;
    address immutable quoteToken;

    address immutable option$0_5;
    address immutable option$1;
    address immutable option$2;
    address immutable option$4;
    address immutable option$8;
    address immutable option$16;

    constructor(
        address underlyingToken_,
        address quoteToken_,
        address option$0_5_,
        address option$1_,
        address option$2_,
        address option$4_,
        address option$8_,
        address option$16_
    ) {
        underlyingToken = underlyingToken_;
        quoteToken = quoteToken_;

        option$0_5 = option$0_5_;
        option$1 = option$1_;
        option$2 = option$2_;
        option$4 = option$4_;
        option$8 = option$8_;
        option$16 = option$16_;
    }

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
                Arbitrum$0_5PutOption(option$0_5).collateral(user),
                Arbitrum$1PutOption(option$1).collateral(user),
                Arbitrum$2PutOption(option$2).collateral(user),
                Arbitrum$4PutOption(option$4).collateral(user),
                Arbitrum$8PutOption(option$8).collateral(user),
                Arbitrum$16PutOption(option$16).collateral(user)
            ),
            OptionTokenBalance(
                Arbitrum$0_5PutOption(option$0_5).balanceOf(user),
                Arbitrum$1PutOption(option$1).balanceOf(user),
                Arbitrum$2PutOption(option$2).balanceOf(user),
                Arbitrum$4PutOption(option$4).balanceOf(user),
                Arbitrum$8PutOption(option$8).balanceOf(user),
                Arbitrum$16PutOption(option$16).balanceOf(user)
            ),
            UnderlyingTokenAllowance(
                IERC20(underlyingToken).allowance(user, option$0_5),
                IERC20(underlyingToken).allowance(user, option$1),
                IERC20(underlyingToken).allowance(user, option$2),
                IERC20(underlyingToken).allowance(user, option$4),
                IERC20(underlyingToken).allowance(user, option$8),
                IERC20(underlyingToken).allowance(user, option$16)
            ),
            QuoteTokenAllowance(
                IERC20(quoteToken).allowance(user, option$0_5),
                IERC20(quoteToken).allowance(user, option$1),
                IERC20(quoteToken).allowance(user, option$2),
                IERC20(quoteToken).allowance(user, option$4),
                IERC20(quoteToken).allowance(user, option$8),
                IERC20(quoteToken).allowance(user, option$16)
            ),
            IERC20(underlyingToken).balanceOf(user),
            IERC20(quoteToken).balanceOf(user)
        );
    }
}
