// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import "openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import "@uma/core/contracts/common/implementation/ExpandedERC20.sol";
import { IERC20Ext } from "../shares/IERC20Ext.sol";
import { UmaTokenHelpers } from "./UmaTokenHelpers.sol";
import { Errors } from "../shares/Errors.sol";
import { IUmaAdapter } from "./interfaces/IUmaAdapter.sol";
import { IUmaFactory } from "./interfaces/IUmaFactory.sol";

// This contract allows to initialize prediction markets each having a pair of binary outcome tokens. Anyone can mint
// and burn the same amount of paired outcome tokens for the default payout currency. Trading of outcome tokens is
// outside the scope of this contract. Anyone can assert 3 possible outcomes (outcome 1, outcome 2 or split) that is
// verified through Optimistic Oracle V3. If the assertion is resolved true then holders of outcome tokens can settle
// them for the payout currency based on resolved market outcome.
contract PredictHubFactory is Initializable, IUmaFactory {
    using SafeERC20 for IERC20;
    uint256 constant _FIXED_SLOT_COUNT = 2;
    uint256 constant _PRECISION = 1e10;
    address private _owner;
    address public exchange;

    mapping(bytes32 => Market) public markets; // Maps marketId to Market struct.

    mapping(bytes32 => AssertedMarket) public assertedMarkets; // Maps assertionId to AssertedMarket.

    IUmaAdapter public umaAdapter;
    IERC20 public currency; // Currency used for all prediction markets.

    mapping(bytes32 => uint[]) public payoutNumerators; // Name of the unresolvable outcome where payouts are split.
    mapping(bytes32 => uint) public payoutDenominator;
    mapping(address => uint256) public whitelisted;
    uint256 public feeConfig;
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
    event MarketRejected(bytes32 indexed marketId);
    event MarketEmergencyResolved(bytes32 indexed marketId);
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
    event AddressUpdated(string name, address value);
    event FeeUpdated(address, uint96);
    event WhitelistUpdated(address[] users, uint256[] status);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(IUmaAdapter _umaAdapter, address _currency) external initializer {
        umaAdapter = _umaAdapter;
        if (!umaAdapter.isWhitelistCurrency(_currency)) {
            revert Errors.UnsupportedCurrency();
        }
        currency = IERC20(_currency);
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != _owner) {
            revert Errors.NotOwner();
        }
        _;
    }

    modifier onlyAdapter() {
        if (msg.sender != address(umaAdapter)) {
            revert Errors.NotAuthorized();
        }
        _;
    }

    function changeOwner(address _newOwner) external onlyOwner {
        _owner = _newOwner;
        emit AddressUpdated("changeOwner", _newOwner);
    }

    function changeExchange(address _exchange) external onlyOwner {
        exchange = _exchange;
        emit AddressUpdated("changeExchange", _exchange);
    }

    function changeAdapter(IUmaAdapter _umaAdapter) external onlyOwner {
        umaAdapter = _umaAdapter;
        emit AddressUpdated("changeAdapter", address(_umaAdapter));
    }

    /// @dev Explain to a developer any extra details
    /// @param _feeManager address of fee manager
    /// @param _feeRate fee rate base on 1e10
    function updateFeeConfig(address _feeManager, uint96 _feeRate) external onlyOwner {
        feeConfig = (uint256(uint160(_feeManager)) << 96) | uint256(_feeRate);
        emit FeeUpdated(_feeManager, _feeRate);
    }

    function configWhitelist(address[] calldata _users, uint256[] calldata _status) external onlyOwner {
        assembly {
            let slot := whitelisted.slot
            let len := _users.length
            let userOffset := _users.offset // Point to the beginning of the array data
            let statusOffset := _status.offset // Point to the beginning of the array data
            let i := 0

            // Start of loop
            for {

            } lt(i, len) {

            } {
                // Load _referers[i] and _rewards[i] from calldata
                let user := calldataload(add(userOffset, mul(i, 32)))
                let status := calldataload(add(statusOffset, mul(i, 32)))

                // Store reward in rewards mapping
                mstore(0, user)
                mstore(32, slot)
                let hash := keccak256(0, 64)
                sstore(hash, status)
                // Increment i
                i := add(i, 1)
            }
            // End of loop
        }
        emit WhitelistUpdated(_users, _status);
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
        marketId = getMarketId(questionId);
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

    // Callback from settled assertion.
    // If the assertion was resolved true, then the asserter gets the reward and the market is marked as resolved.
    // Otherwise, assertedOutcomeId is reset and the market can be asserted again.
    function assertionResolvedAdapterCallback(
        bytes32 assertionId,
        bool assertedTruthfully
    ) public override onlyAdapter {
        bytes32 marketId = assertedMarkets[assertionId].marketId;
        Market storage market = markets[marketId];
        if (market.resolved) {
            return;
        }
        if (assertedTruthfully) {
            if (market.outCome.assertedOutcomeId == keccak256(market.outCome.outcome1)) {
                payoutNumerators[marketId][0] = payoutDenominator[marketId] = _PRECISION;
            } else if (market.outCome.assertedOutcomeId == keccak256(market.outCome.outcome2)) {
                payoutNumerators[marketId][1] = payoutDenominator[marketId] = _PRECISION;
            }
            market.resolved = true;
            if (market.reward > 0) {
                currency.safeTransfer(assertedMarkets[assertionId].asserter, market.reward);
            }
            emit MarketResolved(marketId);
        } else {
            market.outCome.assertedOutcomeId = bytes32(0);
            emit MarketRejected(marketId);
        }
        delete assertedMarkets[assertionId];
    }

    function assertedMarketCallback(
        bytes32 marketId,
        bytes32 assertionId,
        string memory assertedOutcome,
        address asserter
    ) external override onlyAdapter {
        markets[marketId].outCome.assertedOutcomeId = keccak256(bytes(assertedOutcome));
        assertedMarkets[assertionId] = AssertedMarket({ asserter: asserter, marketId: marketId });
        emit MarketAsserted(marketId, assertedOutcome, assertionId);
    }

    function emergencyResolve(
        bytes32 marketId,
        bytes32 assertionId,
        bytes32 outComeId,
        bool isResolve,
        bool isTransferReward
    ) public onlyOwner {
        Market storage market = markets[marketId];
        if (
            outComeId != bytes32(0) &&
            outComeId != keccak256(market.outCome.outcome1) &&
            outComeId != keccak256(market.outCome.outcome2)
        ) {
            revert Errors.InvalidOutCome();
        }

        market.resolved = isResolve;
        market.outCome.assertedOutcomeId = outComeId;
        if (outComeId == keccak256(market.outCome.outcome1)) {
            payoutNumerators[marketId][0] = payoutDenominator[marketId] = _PRECISION;
        } else if (outComeId == keccak256(market.outCome.outcome2)) {
            payoutNumerators[marketId][1] = payoutDenominator[marketId] = _PRECISION;
        }
        if (isTransferReward && market.reward > 0) {
            address receiver = assertedMarkets[assertionId].asserter != address(0)
                ? assertedMarkets[assertionId].asserter
                : msg.sender;
            currency.safeTransfer(receiver, market.reward);
        }
        delete assertedMarkets[assertionId];
        emit MarketEmergencyResolved(marketId);
    }

    function getMarket(bytes32 marketId) external view override returns (Market memory market) {
        return markets[marketId];
    }

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
        for (uint i; i < indexSets.length; ) {
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
            unchecked {
                ++i;
            }
        }

        if (totalPayout > 0) {
            (address feeManager, uint96 feeRate) = getFeeConfig();
            if (feeRate > 0 && whitelisted[msg.sender] == 0) {
                uint256 fee = (totalPayout * feeRate) / _PRECISION;
                currency.safeTransfer(feeManager, fee);
                totalPayout -= fee;
            }
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
        for (uint256 i; i < _partition.length; ) {
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
            unchecked {
                ++i;
            }
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
        outcome1Token.addRoles(address(this));
        outcome2Token.addRoles(address(this));
        outCome = OutCome({
            assertedOutcomeId: bytes32(0),
            outcome1Token: outcome1Token,
            outcome2Token: outcome2Token,
            outcome1: outcome1,
            outcome2: outcome2,
            description: description
        });
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

    function getMarketId(bytes32 questionId) public view returns (bytes32) {
        return UmaTokenHelpers.getMarketId(address(this), questionId, _FIXED_SLOT_COUNT);
    }

    function getTokens(bytes32 marketId) public view returns (address, address) {
        return (address(markets[marketId].outCome.outcome1Token), address(markets[marketId].outCome.outcome2Token));
    }

    function getFeeConfig() public view returns (address feeManager, uint96 feeRate) {
        return (address(uint160(feeConfig >> 96)), uint96(feeConfig));
    }
}
