// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import { IERC20 } from "openzeppelin-contracts/token/ERC20/IERC20.sol";

/// @title IConditionalTokens
/// @notice Interface for the Gnosis ConditionalTokensFramework: https://github.com/gnosis/conditional-tokens-contracts/blob/master/contracts/ConditionalTokens.sol
interface IConditionalTokens {
    function payoutNumerators(bytes32 marketId, uint256 index) external view returns (uint256);

    function payoutDenominator(bytes32 marketId) external view returns (uint256);

    function initializeMarket(
        string memory outcome1, // Short name of the first outcome.
        string memory outcome2, // Short name of the second outcome.
        string memory description, // Description of the market.
        bytes32 questionId, // questionId used for asserting market outcome.
        uint256 reward, // Reward available for asserting true market outcome.
        uint256 requiredBond, // Expected bond to assert market outcome (OOv3 can require higher bond).
        uint64 liveness,
        string memory tokenName1,
        string memory tokenName2
    ) external returns (bytes32 marketId);

    /// @dev This function prepares a condition by initializing a payout vector associated with the condition.
    /// @param oracle The account assigned to report the result for the prepared condition.
    /// @param questionId An identifier for the question to be answered by the oracle.
    /// @param outcomeSlotCount The number of outcome slots which should be used for this condition. Must not exceed 256.
    function prepareCondition(address oracle, bytes32 questionId, uint256 outcomeSlotCount) external;

    /// @dev This function splits a position. If splitting from the collateral, this contract will attempt to transfer `amount` collateral from the message sender to itself. Otherwise, this contract will burn `amount` stake held by the message sender in the position being split worth of EIP 1155 tokens. Regardless, if successful, `amount` stake will be minted in the split target positions. If any of the transfers, mints, or burns fail, the transaction will revert. The transaction will also revert if the given partition is trivial, invalid, or refers to more slots than the condition is prepared with.
    /// @param marketId The ID of the condition to split on.
    /// @param partition An array of disjoint index sets representing a nontrivial partition of the outcome slots of the given condition. E.g. A|B and C but not A|B and B|C (is not disjoint). Each element's a number which, together with the condition, represents the outcome collection. E.g. 0b110 is A|B, 0b010 is B, etc.
    /// @param amount The amount of collateral or stake to split.
    function splitPosition(bytes32 marketId, uint256[] calldata partition, uint256 amount) external;

    /// @dev This function merges CTF tokens into the underlying collateral.
    /// @param marketId The ID of the condition to split on.
    /// @param partition An array of disjoint index sets representing a nontrivial partition of the outcome slots of the given condition. E.g. A|B and C but not A|B and B|C (is not disjoint). Each element's a number which, together with the condition, represents the outcome collection. E.g. 0b110 is A|B, 0b010 is B, etc.
    /// @param amount The amount of collateral or stake to split.
    function mergePositions(bytes32 marketId, uint256[] calldata partition, uint256 amount) external;

    /// @dev This function redeems a CTF ERC1155 token for the underlying collateral
    /// @param marketId The ID of the condition to split on.
    /// @param indexSets Index sets of the outcome collection to combine with the parent outcome collection
    function redeemPositions(bytes32 marketId, uint256[] calldata indexSets) external;

    /// @dev Gets the outcome slot count of a condition.
    /// @param marketId ID of the condition.
    /// @return Number of outcome slots associated with a condition, or zero if condition has not been prepared yet.
    function getOutcomeSlotCount(bytes32 marketId) external view returns (uint256);

    /// @dev Constructs a condition ID from an oracle, a question ID, and the outcome slot count for the question.
    /// @param oracle The account assigned to report the result for the prepared condition.
    /// @param questionId An identifier for the question to be answered by the oracle.
    /// @param outcomeSlotCount The number of outcome slots which should be used for this condition. Must not exceed 256.
    function getMarketId(address oracle, bytes32 questionId, uint256 outcomeSlotCount) external pure returns (bytes32);

    function getMarketId(bytes32 questionId) external pure returns (bytes32);

    /// @dev Constructs an outcome collection ID from a parent collection and an outcome collection.
    /// @param parentCollectionId Collection ID of the parent outcome collection, or bytes32(0) if there's no parent.
    /// @param marketId Condition ID of the outcome collection to combine with the parent outcome collection.
    /// @param indexSet Index set of the outcome collection to combine with the parent outcome collection.
    function getCollectionId(
        bytes32 parentCollectionId,
        bytes32 marketId,
        uint256 indexSet
    ) external view returns (bytes32);

    /// @dev Constructs a position ID from a collateral token and an outcome collection. These IDs are used as the ERC-1155 ID for this contract.
    /// @param collateralToken Collateral token which backs the position.
    /// @param collectionId ID of the outcome collection associated with this position.
    function getPositionId(IERC20 collateralToken, bytes32 collectionId) external pure returns (uint256);

    function getTokens(bytes32 marketId) external pure returns (address, address);

    function assertMarket(bytes32 marketId, string memory assertedOutcome) external returns (bytes32 assertionId);

    function changeExchange(address _exchange) external;

    function approveBatch(address _sender, bytes32 _marketId) external;
}
