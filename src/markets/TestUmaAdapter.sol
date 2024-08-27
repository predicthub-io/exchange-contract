// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import "@uma/core/contracts/common/implementation/AddressWhitelist.sol";
import "@uma/core/contracts/common/implementation/ExpandedERC20.sol";
import "@uma/core/contracts/data-verification-mechanism/implementation/Constants.sol";
import "@uma/core/contracts/data-verification-mechanism/interfaces/FinderInterface.sol";
import "@uma/core/contracts/optimistic-oracle-v3/implementation/ClaimData.sol";
import "@uma/core/contracts/optimistic-oracle-v3/interfaces/OptimisticOracleV3Interface.sol";
import "@uma/core/contracts/optimistic-oracle-v3/interfaces/OptimisticOracleV3CallbackRecipientInterface.sol";
import { IERC20Ext } from "../shares/IERC20Ext.sol";
import { UmaTokenHelpers } from "./UmaTokenHelpers.sol";
import { Errors } from "../shares/Errors.sol";

// This contract allows to initialize prediction markets each having a pair of binary outcome tokens. Anyone can mint
// and burn the same amount of paired outcome tokens for the default payout currency. Trading of outcome tokens is
// outside the scope of this contract. Anyone can assert 3 possible outcomes (outcome 1, outcome 2 or split) that is
// verified through Optimistic Oracle V3. If the assertion is resolved true then holders of outcome tokens can settle
// them for the payout currency based on resolved market outcome.
contract TestUmaAdapter is OptimisticOracleV3CallbackRecipientInterface {
    using SafeERC20 for IERC20;
    uint256 constant _FIXED_SLOT_COUNT = 2;
    uint256 constant _PRECISION = 1e10;
    bytes public constant UNRESOLVABLE = "Unresolvable";
    address private _owner;
    address public exchange;
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

    mapping(bytes32 => Market) public markets; // Maps marketId to Market struct.

    mapping(bytes32 => AssertedMarket) public assertedMarkets; // Maps assertionId to AssertedMarket.

    FinderInterface public immutable finder; // UMA protocol Finder used to discover other protocol contracts.
    IERC20 public immutable currency; // Currency used for all prediction markets.
    OptimisticOracleV3Interface public immutable oo;
    bytes32 public immutable defaultIdentifier; // Identifier used for all prediction markets.
    mapping(bytes32 => uint[]) public payoutNumerators; // Name of the unresolvable outcome where payouts are split.
    mapping(bytes32 => uint) public payoutDenominator;
    event MarketInitialized(
        bytes32 indexed marketId,
        bytes32 indexed questionId,
        string outcome1,
        string outcome2,
        string description,
        address outcome1Token,
        address outcome2Token
    );
    event MarketRewardInitialized(bytes32 indexed marketId, uint256 reward, uint256 requiredBond);
    event MarketAsserted(bytes32 indexed marketId, string assertedOutcome, bytes32 indexed assertionId);
    event MarketResolved(bytes32 indexed marketId);
    event TokensCreated(bytes32 indexed marketId, address indexed account, uint256 tokensCreated);
    event TokensRedeemed(bytes32 indexed marketId, address indexed account, uint256 tokensRedeemed);
    event TokensSettled(
        bytes32 indexed marketId,
        address indexed account,
        uint256 payout,
        uint256 outcome1Tokens,
        uint256 outcome2Tokens
    );
    /// @dev Emitted when a position is successfully split.
    event PositionSplited(address indexed holder, bytes32 indexed marketId, uint[] partition, uint amount);
    /// @dev Emitted when positions are successfully merged.
    event PositionsMerged(address indexed holder, bytes32 indexed marketId, uint[] partition, uint amount);

    event PayoutRedemption(address indexed redeemer, bytes32 indexed marketId, uint[] indexSets, uint payout);

    constructor(address _finder, address _currency, address _optimisticOracleV3) {
        finder = FinderInterface(_finder);
        if (!_getCollateralWhitelist().isOnWhitelist(_currency)) {
            revert Errors.UnsupportedCurrency();
        }
        currency = IERC20(_currency);
        oo = OptimisticOracleV3Interface(_optimisticOracleV3);
        defaultIdentifier = oo.defaultIdentifier();
        _owner = msg.sender;
    }

    function getMarket(bytes32 marketId) public view returns (Market memory) {
        return markets[marketId];
    }

    function changeOwner(address _newOwner) external {
        if (msg.sender != _owner) {
            revert Errors.NotOwner();
        }
        _owner = _newOwner;
    }

    function changeExchange(address _exchange) external {
        if (msg.sender != _owner) {
            revert Errors.PermissionDenied();
        }
        exchange = _exchange;
    }

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
    ) public returns (bytes32 marketId) {
        if (
            bytes(outcome1).length == 0 ||
            bytes(outcome2).length == 0 ||
            keccak256(bytes(outcome1)) == keccak256(bytes(outcome2))
        ) {
            revert Errors.InvalidOutCome();
        }
        if (bytes(description).length == 0) {
            revert Errors.InvalidDesc();
        }

        if (markets[marketId].outCome.outcome1Token != ExpandedIERC20(address(0))) {
            revert Errors.MarketExisted();
        }
        // Create position tokens with this contract having minter and burner roles.
        (ExpandedIERC20 outcome1Token, ExpandedIERC20 outcome2Token, OutCome memory outCome) = _initTokens(
            tokenName1,
            tokenName2,
            bytes(outcome1),
            bytes(outcome2),
            bytes(description)
        );

        marketId = UmaTokenHelpers.getMarketId(address(oo), questionId, _FIXED_SLOT_COUNT);
        markets[marketId] = Market({
            questionId: questionId,
            reward: reward,
            requiredBond: requiredBond,
            liveness: liveness,
            resolved: false,
            outCome: outCome
        });
        payoutNumerators[marketId] = new uint[](_FIXED_SLOT_COUNT);

        if (reward > 0) currency.safeTransferFrom(msg.sender, address(this), reward); // Pull reward.

        emit MarketInitialized(
            marketId,
            questionId,
            outcome1,
            outcome2,
            description,
            address(outcome1Token),
            address(outcome2Token)
        );
        emit MarketRewardInitialized(marketId, reward, requiredBond);
    }

    // Assert the market with any of 3 possible outcomes: names of outcome1, outcome2 or unresolvable.
    // Only one concurrent assertion per market is allowed.
    function assertMarket(bytes32 marketId, string memory assertedOutcome) public returns (bytes32 assertionId) {
        Market storage market = markets[marketId];
        if (markets[marketId].outCome.outcome1Token == ExpandedIERC20(address(0))) {
            revert Errors.MarketNotExist();
        }
        bytes32 assertedOutcomeId = keccak256(bytes(assertedOutcome));
        if (markets[marketId].outCome.assertedOutcomeId != bytes32(0)) {
            revert Errors.ActivedOrResolved();
        }
        if (
            !(assertedOutcomeId == keccak256(market.outCome.outcome1) ||
                assertedOutcomeId == keccak256(market.outCome.outcome2) ||
                assertedOutcomeId == keccak256(UNRESOLVABLE))
        ) {
            revert Errors.InvalidAssertedOutcome();
        }

        markets[marketId].outCome.assertedOutcomeId = assertedOutcomeId;
        uint256 minimumBond = oo.getMinimumBond(address(currency)); // OOv3 might require higher bond.
        uint256 bond = markets[marketId].requiredBond > minimumBond ? markets[marketId].requiredBond : minimumBond;
        bytes memory claim = _composeClaim(assertedOutcome, markets[marketId].outCome.description);

        // Pull bond and make the assertion.
        currency.safeTransferFrom(msg.sender, address(this), bond);
        currency.safeApprove(address(oo), bond);

        assertionId = _assertTruthWithDefaults(claim, bond, markets[marketId].liveness);

        // Store the asserter and marketId for the assertionResolvedCallback.
        assertedMarkets[assertionId] = AssertedMarket({ asserter: msg.sender, marketId: marketId });

        emit MarketAsserted(marketId, assertedOutcome, assertionId);
    }

    // Callback from settled assertion.
    // If the assertion was resolved true, then the asserter gets the reward and the market is marked as resolved.
    // Otherwise, assertedOutcomeId is reset and the market can be asserted again.
    function assertionResolvedCallback(bytes32 assertionId, bool assertedTruthfully) public {
        if (msg.sender != address(oo)) revert Errors.NotAuthorized();
        Market storage market = markets[assertedMarkets[assertionId].marketId];
        if (assertedTruthfully) {
            bytes32 marketId = assertedMarkets[assertionId].marketId;
            if (market.outCome.assertedOutcomeId == keccak256(market.outCome.outcome1)) {
                payoutNumerators[marketId][0] = payoutDenominator[marketId] = _PRECISION;
            } else if (market.outCome.assertedOutcomeId == keccak256(market.outCome.outcome2)) {
                payoutNumerators[marketId][1] = payoutDenominator[marketId] = _PRECISION;
            }
            market.resolved = true;
            if (market.reward > 0) currency.safeTransfer(assertedMarkets[assertionId].asserter, market.reward);
            emit MarketResolved(marketId);
        } else market.outCome.assertedOutcomeId = bytes32(0);
        delete assertedMarkets[assertionId];
    }

    // Dispute callback does nothing.
    function assertionDisputedCallback(bytes32 assertionId) public {}

    // Mints pair of tokens representing the value of outcome1 and outcome2. Trading of outcome tokens is outside of the
    // scope of this contract. The caller must approve this contract to spend the currency tokens.
    // function createOutcomeTokens(bytes32 marketId, uint256 tokensToCreate) public {
    //     if (markets[marketId].outCome.outcome1Token != ExpandedIERC20(address(0))) {
    //         revert Errors.MarketNotExist();
    //     }
    //     currency.safeTransferFrom(msg.sender, address(this), tokensToCreate);
    //     markets[marketId].outCome.outcome1Token.mint(msg.sender, tokensToCreate);
    //     markets[marketId].outCome.outcome2Token.mint(msg.sender, tokensToCreate);
    //     emit TokensCreated(marketId, msg.sender, tokensToCreate);
    // }

    function redeemPositions(bytes32 marketId, uint256[] calldata indexSets) external {
        uint den = payoutDenominator[marketId];
        if (den == 0) {
            revert Errors.MarketNotResolved();
        }
        uint outcomeSlotCount = payoutNumerators[marketId].length;
        if (outcomeSlotCount == 0) revert Errors.MarketNotExist();

        Market memory market = markets[marketId];
        uint totalPayout = 0;

        uint fullIndexSet = (1 << outcomeSlotCount) - 1;
        for (uint i = 0; i < indexSets.length; i++) {
            uint indexSet = indexSets[i];
            if (!(indexSet > 0 && indexSet < fullIndexSet)) {
                revert Errors.InvalidIndexSet();
            }

            ExpandedIERC20 marketToken = _getMarketConditionTokens(market, indexSet);
            uint payoutNumerator = 0;
            for (uint j; j < outcomeSlotCount; ) {
                if (indexSet & (1 << j) != 0) {
                    payoutNumerator += payoutNumerators[marketId][j];
                }
                unchecked {
                    ++j;
                }
            }

            uint payoutStake = marketToken.balanceOf(msg.sender);
            if (payoutStake > 0) {
                totalPayout = totalPayout + (payoutStake * payoutNumerator) / den;
                marketToken.burnFrom(msg.sender, payoutStake);
            }
        }

        if (totalPayout > 0) {
            currency.safeTransfer(msg.sender, totalPayout);
        }
        emit PayoutRedemption(msg.sender, marketId, indexSets, totalPayout);
    }

    function splitPosition(bytes32 marketId, uint256[] calldata partition, uint256 amount) external {
        Market memory market = markets[marketId];
        (
            ExpandedIERC20[] memory marketTokens,
            uint256[] memory amounts,
            uint256 fullIndexSet,
            uint256 freeIndexSet
        ) = _checkPartition(marketId, market, partition, amount);

        if (freeIndexSet == 0) {
            // Partitioning the full set of outcomes for the condition in this branch
            currency.safeTransferFrom(msg.sender, address(this), amount);
        } else {
            // Partitioning a subset of outcomes for the condition in this branch.
            // For example, for a condition with three outcomes A, B, and C, this branch
            // allows the splitting of a position $:(A|C) to positions $:(A) and $:(C).
            _getMarketConditionTokens(market, fullIndexSet ^ freeIndexSet).burnFrom(msg.sender, amount);
        }

        _mintBatch(msg.sender, marketTokens, amounts);
        emit PositionSplited(msg.sender, marketId, partition, amount);
    }

    function mergePositions(bytes32 marketId, uint256[] calldata partition, uint256 amount) external {
        Market memory market = markets[marketId];
        (
            ExpandedIERC20[] memory marketTokens,
            uint256[] memory amounts,
            uint256 fullIndexSet,
            uint256 freeIndexSet
        ) = _checkPartition(marketId, market, partition, amount);
        _burnBatch(msg.sender, marketTokens, amounts);
        if (freeIndexSet == 0) {
            currency.safeTransfer(msg.sender, amount);
        } else {
            _getMarketConditionTokens(market, fullIndexSet ^ freeIndexSet).mint(msg.sender, amount);
        }

        emit PositionsMerged(msg.sender, marketId, partition, amount);
    }

    function approveBatch(address _sender, bytes32 _marketId) external {
        (address token1, address token2) = getTokens(_marketId);
        ExpandedIERC20(token1).approveMaxFor(_sender, exchange);
        ExpandedIERC20(token2).approveMaxFor(_sender, exchange);
    }

    function _checkPartition(
        bytes32 _marketId,
        Market memory _market,
        uint256[] calldata _partition,
        uint256 _amount
    )
        internal
        view
        returns (
            ExpandedIERC20[] memory marketTokens,
            uint256[] memory amounts,
            uint256 fullIndexSet,
            uint256 freeIndexSet
        )
    {
        if (_partition.length <= 1) revert Errors.InvalidPartition();
        uint256 outcomeSlotCount = payoutNumerators[_marketId].length;
        if (outcomeSlotCount == 0) revert Errors.MarketNotExist();
        fullIndexSet = (1 << outcomeSlotCount) - 1;
        freeIndexSet = fullIndexSet;
        marketTokens = new ExpandedIERC20[](_partition.length);
        amounts = new uint256[](_partition.length);
        for (uint256 i; i < _partition.length; ++i) {
            uint256 indexSet = _partition[i];
            if (!(indexSet > 0 && indexSet < fullIndexSet)) {
                revert Errors.InvalidIndexSet();
            }
            if (!((indexSet & freeIndexSet) == indexSet)) {
                revert Errors.PartitionNotDisjoint();
            }
            freeIndexSet ^= indexSet;
            marketTokens[i] = _getMarketConditionTokens(_market, indexSet);
            amounts[i] = _amount;
        }
    }

    function _initTokens(
        string memory tokenName1,
        string memory tokenName2,
        bytes memory outcome1,
        bytes memory outcome2,
        bytes memory description
    ) internal returns (ExpandedIERC20 outcome1Token, ExpandedIERC20 outcome2Token, OutCome memory outCome) {
        uint8 decimals = IERC20Ext(address(currency)).decimals();
        outcome1Token = new ExpandedERC20(tokenName1, tokenName1, decimals);
        outcome2Token = new ExpandedERC20(tokenName2, tokenName2, decimals);
        outcome1Token.addMinter(address(this));
        outcome2Token.addMinter(address(this));
        outcome1Token.addBurner(address(this));
        outcome2Token.addBurner(address(this));
        outcome1Token.addApprover(address(this));
        outcome2Token.addApprover(address(this));
        outCome = OutCome({
            assertedOutcomeId: bytes32(0),
            outcome1Token: outcome1Token,
            outcome2Token: outcome2Token,
            outcome1: outcome1,
            outcome2: outcome2,
            description: description
        });
    }

    function _getCollateralWhitelist() internal view returns (AddressWhitelist) {
        return AddressWhitelist(finder.getImplementationAddress(OracleInterfaces.CollateralWhitelist));
    }

    function _mintBatch(address _sender, ExpandedIERC20[] memory marketTokens, uint256[] memory amounts) private {
        for (uint256 i; i < marketTokens.length; ) {
            marketTokens[i].mint(_sender, amounts[i]);
            unchecked {
                ++i;
            }
        }
    }

    function _burnBatch(address _sender, ExpandedIERC20[] memory marketTokens, uint256[] memory amounts) private {
        for (uint256 i; i < marketTokens.length; ) {
            marketTokens[i].burnFrom(_sender, amounts[i]);
            unchecked {
                ++i;
            }
        }
    }

    function _getMarketConditionTokens(Market memory market, uint256 indexSet) private pure returns (ExpandedIERC20) {
        if (indexSet == 1) {
            return market.outCome.outcome1Token;
        } else if (indexSet == 2) {
            return market.outCome.outcome2Token;
        }
        revert Errors.InvalidIndexSet();
    }

    function _composeClaim(string memory outcome, bytes memory description) internal view returns (bytes memory) {
        return
            abi.encodePacked(
                "The described prediction market outcome is: ",
                outcome,
                ". The market description is: ",
                description,
                "At timestamp ",
                ClaimData.toUtf8BytesUint(block.timestamp)
            );
    }

    function _assertTruthWithDefaults(
        bytes memory claim,
        uint256 bond,
        uint64 assertionLiveness
    ) internal returns (bytes32 assertionId) {
        assertionId = oo.assertTruth(
            claim,
            msg.sender, // Asserter
            address(this), // Receive callback in this contract.
            address(0), // No sovereign security.
            assertionLiveness,
            currency,
            bond,
            defaultIdentifier,
            bytes32(0) // No domain.
        );
    }

    function getMarketId(bytes32 questionId) external view returns (bytes32) {
        return UmaTokenHelpers.getMarketId(address(oo), questionId, _FIXED_SLOT_COUNT);
    }

    function getTokens(bytes32 marketId) public view returns (address, address) {
        return (address(markets[marketId].outCome.outcome1Token), address(markets[marketId].outCome.outcome2Token));
    }
}
