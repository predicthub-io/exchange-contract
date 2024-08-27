// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;
import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import "@uma/core/contracts/optimistic-oracle-v3/interfaces/OptimisticOracleV3Interface.sol";
import "@uma/core/contracts/optimistic-oracle-v3/interfaces/OptimisticOracleV3CallbackRecipientInterface.sol";
import "@uma/core/contracts/data-verification-mechanism/interfaces/FinderInterface.sol";
import "@uma/core/contracts/common/implementation/AddressWhitelist.sol";
import "@uma/core/contracts/data-verification-mechanism/implementation/Constants.sol";
import "@uma/core/contracts/optimistic-oracle-v3/implementation/ClaimData.sol";
import { IUmaFactory } from "./interfaces/IUmaFactory.sol";
import { Errors } from "../shares/Errors.sol";

// This contract allows to initialize prediction markets each having a pair of binary outcome tokens. Anyone can mint
// and burn the same amount of paired outcome tokens for the default payout currency. Trading of outcome tokens is
// outside the scope of this contract. Anyone can assert 3 possible outcomes (outcome 1, outcome 2 or split) that is
// verified through Optimistic Oracle V3. If the assertion is resolved true then holders of outcome tokens can settle
// them for the payout currency based on resolved market outcome.
contract UmaAdapter is Ownable, OptimisticOracleV3CallbackRecipientInterface {
    using SafeERC20 for IERC20;
    bytes public constant UNRESOLVABLE = "Unresolvable";
    IUmaFactory public factory;
    FinderInterface public finder;
    OptimisticOracleV3Interface public oo;
    address public whitelistDisputerManager;
    event FactoryUpdated(address);
    event WhitelistDisputerManagerUpdated(address);

    constructor(address _finder, address _optimisticOracleV3) {
        finder = FinderInterface(_finder);
        oo = OptimisticOracleV3Interface(_optimisticOracleV3);
    }

    function setFactory(IUmaFactory _factory) external onlyOwner {
        factory = _factory;
        emit FactoryUpdated(address(_factory));
    }

    function setWhitelistDisputerManager(address _whitelistDisputerManager) external onlyOwner {
        whitelistDisputerManager = _whitelistDisputerManager;
        emit WhitelistDisputerManagerUpdated(_whitelistDisputerManager);
    }

    // Assert the market with any of 3 possible outcomes: names of outcome1, outcome2 or unresolvable.
    // Only one concurrent assertion per market is allowed.
    function assertMarket(
        bytes32 marketId,
        string memory assertedOutcome
    ) public returns (bytes32 assertedOutcomeId, bytes32 assertionId) {
        IUmaFactory.Market memory market = factory.getMarket(marketId);
        if (address(market.outCome.outcome1Token) == address(0)) {
            revert Errors.MarketNotExist();
        }
        assertedOutcomeId = keccak256(bytes(assertedOutcome));
        if (market.outCome.assertedOutcomeId != bytes32(0)) {
            revert Errors.ActivedOrResolved();
        }
        if (
            assertedOutcomeId != keccak256(market.outCome.outcome1) &&
            assertedOutcomeId != keccak256(market.outCome.outcome2)
        ) {
            revert Errors.InvalidAssertedOutcome();
        }
        IERC20 currency = factory.currency();
        uint256 minimumBond = oo.getMinimumBond(address(currency)); // OOv3 might require higher bond.
        uint256 bond = market.requiredBond > minimumBond ? market.requiredBond : minimumBond;
        bytes memory claim = _composeClaim(assertedOutcome, market.outCome.description);

        // Pull bond and make the assertion.
        currency.safeTransferFrom(msg.sender, address(this), bond);
        currency.safeApprove(address(oo), bond);
        assertionId = _assertTruthWithDefaults(claim, bond, market.liveness);
        factory.assertedMarketCallback(marketId, assertionId, assertedOutcome, msg.sender);
    }

    function assertionResolvedCallback(bytes32 assertionId, bool assertedTruthfully) public {
        if (msg.sender != address(oo)) revert Errors.NotAuthorized();
        factory.assertionResolvedAdapterCallback(assertionId, assertedTruthfully);
    }

    // Dispute callback does nothing.
    function assertionDisputedCallback(bytes32 assertionId) public {}

    function isWhitelistCurrency(address _currency) external view returns (bool) {
        return
            (AddressWhitelist(finder.getImplementationAddress(OracleInterfaces.CollateralWhitelist))).isOnWhitelist(
                _currency
            );
    }

    function _composeClaim(string memory outcome, bytes memory description) internal view returns (bytes memory) {
        return
            abi.encodePacked(
                "The described prediction market outcome is: ",
                outcome,
                ". The market description is: ",
                description,
                "At timestamp: ",
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
            whitelistDisputerManager, // No sovereign security.
            assertionLiveness,
            factory.currency(),
            bond,
            oo.defaultIdentifier(),
            bytes32(0) // No domain.
        );
    }
}
