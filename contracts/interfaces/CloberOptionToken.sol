// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

/**
 * @title CloberOptionToken
 * @notice This interface defines the functions and events for an option token on the Clober protocol.
 */
interface CloberOptionToken {
    /**
     * @dev Emitted when an option writer options.
     * @param writer The address of the option writer.
     * @param amount The amount of options written.
     */
    event Write(address indexed writer, uint256 amount);

    /**
     * @dev Emitted when an option writer cancels options before expiration.
     * @param writer The address of the option writer.
     * @param amount The amount of options cancelled.
     */
    event Cancel(address indexed writer, uint256 amount);

    /**
     * @dev Emitted when an option holder exercises options before expiration.
     * @param recipient The address of the option recipient.
     * @param amount The amount of options exercised.
     */
    event Exercise(address indexed recipient, uint256 amount);

    /**
     * @dev Emitted when an option holder claims the underlying asset after exercise.
     * @param recipient The address of the option recipient.
     * @param amount The amount of underlying asset claimed.
     */
    event Claim(address indexed recipient, uint256 amount);

    /**
     * @dev Emitted when the exercise fee is collected from the option holder.
     * @param recipient The address of the fee recipient.
     * @param amount The amount of fee collected.
     */
    event CollectFee(address indexed recipient, uint256 amount);

    /**
     * @notice Returns the address of the underlying asset for the option.
     * @return The address of the underlying asset.
     */
    function underlyingToken() external view returns (address);

    /**
     * @notice Returns the address of the quote asset for the option.
     * @return The address of the quote asset.
     */
    function quoteToken() external view returns (address);

    /**
     * @notice Returns the collateral balance for the given address.
     * @param user The address to check the balance for.
     * @return The collateral balance for the given address.
     */
    function collateral(address user) external view returns (uint256);

    /**
     * @notice Returns the strike price of the option.
     * @return The strike price of the option.
     */
    function strikePrice() external view returns (uint256);

    /**
     * @notice Returns the amount of options that have been exercised.
     * @return The amount of options that have been exercised.
     */
    function exercisedAmount() external view returns (uint256);

    /**
     * @notice Returns the expiration timestamp for the option.
     * @return The expiration timestamp for the option.
     */
    function expiresAt() external view returns (uint256);

    /**
     * @notice Returns the exercise fee percentage for the option.
     * @return The exercise fee percentage for the option.
     */
    function exerciseFee() external view returns (uint256);

    /**
     * @notice Returns the exercise fee balance for the option.
     * @return The exercise fee balance for the option.
     */
    function exerciseFeeBalance() external view returns (uint256);

    /**
     * @notice Allows an address to write options.
     * @param optionAmount The amount of options to write.
     */
    function write(uint256 optionAmount) external;

    /**
     * @notice Allows an option writer to cancel options before expiration.
     * @param optionAmount The amount of options to cancel.
     */
    function cancel(uint256 optionAmount) external;

    /**
     * @notice Allows an option holder to exercise options before expiration.
     * @param optionAmount The amount of options to exercise.
     */
    function exercise(uint256 optionAmount) external;

    /**
     * @notice Allows an option holder to claim the underlying asset after exercise.
     */
    function claim() external;
}