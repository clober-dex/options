pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./CallOptionToken.sol";
import "./PutOptionToken.sol";
import "./interfaces/CloberOptionFactory.sol";
import "./libary/BoringERC20.sol";
import "./libary/DateTime.sol";
import "./libary/StringUtils.sol";

contract OptionFactory is CloberOptionFactory, Ownable {
    using BoringERC20 for IERC20;

    uint256 private constant _PRECISION = 10**18;

    address private immutable _underlyingToken;
    address private immutable _quoteToken;
    uint256 private immutable _exerciseFee;

    constructor(
        address underlyingToken_,
        address quoteToken_,
        uint256 exerciseFee_
    ) {
        _underlyingToken = underlyingToken_;
        _quoteToken = quoteToken_;
        _exerciseFee = exerciseFee_;
    }

    function deployOptions(OptionParams[] calldata optionParams)
        external
        onlyOwner
        returns (address[] memory optionAddresses)
    {
        uint256 length = optionParams.length;
        optionAddresses = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            string memory strikePriceString = StringUtils.uint256ToString(optionParams[i].strikePrice, _PRECISION);
            (uint256 year, uint256 month, uint256 day) = DateTime.timestampToDate(optionParams[i].expiresAt);
            string memory name = string(
                // Ethereum Call Option Expires 230324-1800-C
                abi.encodePacked(
                    IERC20(_underlyingToken).safeName(),
                    optionParams[i].call ? " Call Options at " : " Put Options at ",
                    strikePriceString,
                    " ",
                    IERC20(_quoteToken).safeSymbol(),
                    " (exp.",
                    StringUtils.toString(year * 10000 + month * 100 + day),
                    ")"
                )
            );
            string memory symbol = string(
                // ETH-230324-1800-C
                abi.encodePacked(
                    IERC20(_underlyingToken).safeSymbol(),
                    "-",
                    StringUtils.toString(year * 10000 + month * 100 + day),
                    "-",
                    strikePriceString,
                    "-",
                    optionParams[i].call ? "C" : "P"
                )
            );

            if (optionParams[i].call) {
                optionAddresses[i] = address(
                    new CallOptionToken(
                        _underlyingToken,
                        _quoteToken,
                        optionParams[i].strikePrice,
                        optionParams[i].expiresAt,
                        _exerciseFee,
                        name,
                        symbol
                    )
                );
            } else {
                optionAddresses[i] = address(
                    new PutOptionToken(
                        _underlyingToken,
                        _quoteToken,
                        optionParams[i].strikePrice,
                        optionParams[i].expiresAt,
                        _exerciseFee,
                        name,
                        symbol
                    )
                );
            }
        }
    }
}
