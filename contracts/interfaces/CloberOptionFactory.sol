pragma solidity ^0.8.0;

interface CloberOptionFactory {
    struct OptionParams {
        bool call;
        uint256 expiresAt;
        uint256 strikePrice;
    }

    function deployOptions(OptionParams[] calldata) external returns (address[] memory);
}
