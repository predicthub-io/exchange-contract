// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import "openzeppelin-contracts/token/ERC20/IERC20.sol";
import "@uma/core/contracts/optimistic-oracle-v3/interfaces/OptimisticOracleV3Interface.sol";
import "@uma/core/contracts/common/interfaces/ExpandedIERC20.sol";

interface IUmaFactory {
    struct OutCome {
        ExpandedIERC20 outcome1Token; // ERC20 token representing the value of the first outcome.
        ExpandedIERC20 outcome2Token;
        bytes32 assertedOutcomeId; // Hash of asserted outcome (outcome1, outcome2 or unresolvable).
        bytes outcome1; // Short name of the first outcome.
        bytes outcome2; // Short name of the second outcome.
        bytes description; // Description of the market.
    }
    struct Market {
        bytes32 questionId;
        uint256 reward; // Reward available for asserting true market outcome.
        uint256 requiredBond; // Expected bond to assert market outcome (OOv3 can require higher bond).
        uint64 liveness;
        bool resolved; // True if the market has been resolved and payouts can be settled.
        OutCome outCome;
    }

    struct AssertedMarket {
        address asserter; // Address of the asserter used for reward payout.
        bytes32 marketId; // Identifier for markets mapping.
    }

    function getMarket(bytes32 marketId) external view returns (Market memory market);

    function getAssertedMarket(bytes32 assertionId) external view returns (AssertedMarket memory assertedMarket);

    function assertedMarketCallback(
        bytes32 marketId,
        bytes32 assertionId,
        string memory assertedOutcome,
        address asserter
    ) external;

    function assertionResolvedAdapterCallback(bytes32 assertionId, bool assertedTruthfully) external;

    function currency() external returns (IERC20);
}
