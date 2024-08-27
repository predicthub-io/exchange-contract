// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;
import { console2 as console } from "forge-std/Test.sol";
import "openzeppelin-contracts/token/ERC20/IERC20.sol";
import "@uma/core/contracts/common/implementation/AddressWhitelist.sol";
import "@uma/core/contracts/common/implementation/TestnetERC20.sol";
import "@uma/core/contracts/data-verification-mechanism/implementation/Constants.sol";
import "@uma/core/contracts/data-verification-mechanism/implementation/Finder.sol";
import "@uma/core/contracts/data-verification-mechanism/implementation/IdentifierWhitelist.sol";
import "@uma/core/contracts/data-verification-mechanism/implementation/Store.sol";
import "@uma/core/contracts/data-verification-mechanism/test/MockOracleAncillary.sol";
import "@uma/core/contracts/optimistic-oracle-v3/implementation/OptimisticOracleV3.sol";

import { TestHelper } from "dev/TestHelper.sol";
import { USDC } from "dev/mocks/USDC.sol";
import { Deployer } from "dev/util/Deployer.sol";

import { IERC20 } from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import { IERC1155 } from "openzeppelin-contracts/token/ERC1155/IERC1155.sol";

import { PredictHubExchange } from "exchange/PredictHubExchange.sol";
import { ConditionalTokens } from "token/ConditionalTokens.sol";
import { TestUmaAdapter } from "markets/TestUmaAdapter.sol";
import { IAuthEE } from "exchange/interfaces/IAuth.sol";
import { IFeesEE } from "exchange/interfaces/IFees.sol";
import { ITradingEE } from "exchange/interfaces/ITrading.sol";
import { IPausableEE } from "exchange/interfaces/IPausable.sol";
import { IRegistryEE } from "exchange/interfaces/IRegistry.sol";
import { ISignaturesEE } from "exchange/interfaces/ISignatures.sol";

import { IConditionalTokens } from "exchange/interfaces/IConditionalTokens.sol";

import { CalculatorHelper } from "exchange/libraries/CalculatorHelper.sol";
import { Order, Side, MatchType, OrderStatus, SignatureType } from "exchange/libraries/OrderStructs.sol";

contract BaseExchangeTest is TestHelper, IAuthEE, IFeesEE, IRegistryEE, IPausableEE, ITradingEE, ISignaturesEE {
    mapping(address => mapping(address => mapping(uint256 => uint256))) private _checkpoints1155;

    // Deployment parameters are set as state variables to avoid stack too deep errors.
    bytes32 defaultIdentifier; // Defaults to ASSERT_TRUTH.
    uint256 minimumBond; // Defaults to 100e18 (finalFee will be set to half of this value).
    uint64 defaultLiveness; // Defaults to 2h.
    address defaultCurrency; // If not set, a new TestnetERC20 will be deployed.
    string defaultCurrencyName; // Defaults to "Default Bond Token", only used if DEFAULT_CURRENCY is not set.
    string defaultCurrencySymbol; // Defaults to "DBT", only used if DEFAULT_CURRENCY is not set.
    uint8 defaultCurrencyDecimals; // Defaults to 18, only used if DEFAULT_CURRENCY is not set.

    USDC public usdc;
    IConditionalTokens public ctf;
    PredictHubExchange public exchange;
    TestUmaAdapter public conditionalTokens;
    bytes32 public constant questionID = hex"1234";
    bytes32 public marketId;
    string public yesAnswer = "true";
    string public noAnswer = "false";
    OptimisticOracleV3 public oo;
    uint256 public yes;
    uint256 public no;

    string public desc = "Are you ok?";
    address public admin = alice;
    uint256 internal bobPK = 0xB0B;
    uint256 internal carlaPK = 0xCA414;
    uint256 internal annaPK = 0x35a01;
    address public bob;
    address public carla;
    address public anna;
    // ERC20 transfer event
    event Transfer(address indexed from, address indexed to, uint256 value);

    // ERC1155 transfer event
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    function setUp() public virtual {
        defaultIdentifier = bytes32("ASSERT_TRUTH");
        minimumBond = uint256(100e6);
        defaultLiveness = uint64(3600);
        defaultCurrency = address(0);

        Finder finder = new Finder();
        console.log("Deployed Finder at %s", address(finder));
        Store store = new Store(FixedPoint.fromUnscaledUint(0), FixedPoint.fromUnscaledUint(0), address(0));
        console.log("Deployed Store at %s", address(store));
        AddressWhitelist addressWhitelist = new AddressWhitelist();
        console.log("Deployed AddressWhitelist at %s", address(addressWhitelist));
        IdentifierWhitelist identifierWhitelist = new IdentifierWhitelist();
        console.log("Deployed IdentifierWhitelist at %s", address(identifierWhitelist));
        MockOracleAncillary mockOracle = new MockOracleAncillary(address(finder), address(0));
        console.log("Deployed MockOracleAncillary at %s", address(mockOracle));
        usdc = new USDC();
        vm.label(address(usdc), "USDC");
        if (defaultCurrency == address(0)) {
            defaultCurrency = address(usdc);
            console.log("Deployed TestnetERC20 at %s", defaultCurrency);
            console.log("Deployed usdc at %s", address(usdc));
        }

        // Register UMA ecosystem contracts, whitelist currency and identifier.
        finder.changeImplementationAddress(OracleInterfaces.Store, address(store));
        finder.changeImplementationAddress(OracleInterfaces.CollateralWhitelist, address(addressWhitelist));
        finder.changeImplementationAddress(OracleInterfaces.IdentifierWhitelist, address(identifierWhitelist));
        finder.changeImplementationAddress(OracleInterfaces.Oracle, address(mockOracle));
        addressWhitelist.addToWhitelist(defaultCurrency);
        identifierWhitelist.addSupportedIdentifier(defaultIdentifier);
        store.setFinalFee(defaultCurrency, FixedPoint.Unsigned(minimumBond / 2));

        // Deploy Optimistic Oracle V3 and register it in the Finder.
        oo = new OptimisticOracleV3(finder, IERC20(defaultCurrency), defaultLiveness);
        console.log("Deployed Optimistic Oracle V3 at %s", address(oo));
        finder.changeImplementationAddress(OracleInterfaces.OptimisticOracleV3, address(oo));

        bob = vm.addr(bobPK);
        vm.label(bob, "bob");
        carla = vm.addr(carlaPK);
        vm.label(carla, "carla");

        anna = vm.addr(annaPK);
        vm.label(anna, "anna");
        conditionalTokens = new TestUmaAdapter(address(finder), address(usdc), address(oo));
        ctf = IConditionalTokens(address(conditionalTokens));
        vm.label(address(ctf), "UMAAdapter");

        marketId = _prepareCondition(questionID);
        (yes, no) = _getTokenAddressAndConvert(marketId);
        vm.label(address(uint160(yes)), "YesToken");
        vm.label(address(uint160(no)), "NoToken");
        vm.startPrank(admin);
        exchange = new PredictHubExchange(address(usdc), address(ctf), address(0));

        exchange.registerToken(yes, no, marketId);
        exchange.addOperator(bob);
        exchange.addOperator(carla);
        vm.stopPrank();
        ctf.changeExchange(address(exchange));
    }

    function _prepareCondition(bytes32 _questionId) internal returns (bytes32) {
        ctf.initializeMarket(yesAnswer, noAnswer, desc, _questionId, 0, minimumBond, uint64(3600), "YES", "NO");
        return ctf.getMarketId(_questionId);
    }

    function _getTokenAddressAndConvert(bytes32 _marketId) internal view returns (uint256, uint256) {
        (address token1, address token2) = ctf.getTokens(_marketId);
        return (uint256(uint160(token1)), uint256(uint160(token2)));
    }

    function _createAndSignOrderWithFee(
        uint256 pk,
        uint256 tokenId,
        uint256 makerAmount,
        uint256 takerAmount,
        uint256 feeRateBps,
        Side side
    ) internal returns (Order memory) {
        address maker = vm.addr(pk);
        Order memory order = _createOrder(maker, tokenId, makerAmount, takerAmount, side);
        order.feeRateBps = feeRateBps;
        order.signature = _signMessage(pk, exchange.hashOrder(order));
        return order;
    }

    function _createAndSignOrder(
        uint256 pk,
        uint256 tokenId,
        uint256 makerAmount,
        uint256 takerAmount,
        Side side
    ) internal returns (Order memory) {
        address maker = vm.addr(pk);
        Order memory order = _createOrder(maker, tokenId, makerAmount, takerAmount, side);
        order.signature = _signMessage(pk, exchange.hashOrder(order));
        return order;
    }

    function _createOrder(
        address maker,
        uint256 tokenId,
        uint256 makerAmount,
        uint256 takerAmount,
        Side side
    ) internal pure returns (Order memory) {
        Order memory order = Order({
            salt: 1,
            signer: maker,
            maker: maker,
            taker: address(0),
            tokenId: tokenId,
            makerAmount: makerAmount,
            takerAmount: takerAmount,
            expiration: 0,
            nonce: 0,
            feeRateBps: 0,
            signatureType: SignatureType.EOA,
            side: side,
            signature: new bytes(0)
        });
        return order;
    }

    function _signMessage(uint256 pk, bytes32 message) internal returns (bytes memory sig) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(pk, message);
        sig = abi.encodePacked(r, s, v);
    }

    function _mintTestTokens(address to, address spender, uint256 amount) internal {
        uint256[] memory partition = new uint256[](2);
        partition[0] = 1;
        partition[1] = 2;

        vm.startPrank(to);
        approve(address(usdc), address(ctf), type(uint256).max);
        dealAndApprove(address(usdc), to, spender, amount);

        //approve(address(uint160(yes)), address(spender), type(uint256).max);
        //approve(address(uint160(no)), address(spender), type(uint256).max);

        uint256 splitAmount = amount / 2;
        IConditionalTokens(ctf).splitPosition(marketId, partition, splitAmount);
        console.log("splitAmount: %s", splitAmount);
        vm.stopPrank();
    }

    function assertCollateralBalance(address _who, uint256 _amount) public {
        assertBalance(address(usdc), _who, _amount);
    }

    function assertCTFBalance(address _who, uint256 _tokenId, uint256 _amount) public {
        assertBalance1155(address(ctf), _who, _tokenId, _amount);
    }

    function checkpointCollateral(address _who) public {
        checkpointBalance(address(usdc), _who);
    }

    function checkpointCTF(address _who, uint256 _tokenId) public {
        checkpointBalance1155(address(ctf), _who, _tokenId);
    }

    function getCTFBalance(address _who, uint256 _tokenId) public view returns (uint256) {
        return IERC20(address(uint160(_tokenId))).balanceOf(_who);
    }

    function assertBalance1155(address _token, address _who, uint256 _tokenId, uint256 _amount) public {
        assertEq(getCTFBalance(_who, _tokenId), _checkpoints1155[_token][_who][_tokenId] + _amount);
    }

    function checkpointBalance1155(address _token, address _who, uint256 _tokenId) public {
        _checkpoints1155[_token][_who][_tokenId] = getCTFBalance(_who, _tokenId);
    }

    function calculatePrice(uint256 makerAmount, uint256 takerAmount, Side side) public pure returns (uint256) {
        return CalculatorHelper._calculatePrice(makerAmount, takerAmount, side);
    }

    function calculateFee(
        uint256 _feeRate,
        uint256 _amount,
        uint256 makerAmount,
        uint256 takerAmount,
        Side side
    ) internal pure returns (uint256) {
        return CalculatorHelper.calculateFee(_feeRate, _amount, makerAmount, takerAmount, side);
    }

    function _getTakingAmount(
        uint256 _making,
        uint256 _makerAmount,
        uint256 _takerAmount
    ) internal pure returns (uint256) {
        return (_making * _takerAmount) / _makerAmount;
    }
}
