// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { Script } from "forge-std/Script.sol";
import { PredictHubExchange } from "exchange/PredictHubExchange.sol";

/// @title ExchangeDeployment
/// @notice Script to deploy the CTF Exchange
/// @author PredictHub
contract ExchangeDeployment is Script {
    /// @notice Deploys the Exchange contract
    /// @param admin        - The admin for the Exchange
    /// @param collateral   - The collateral token address
    /// @param ctf          - The CTF address
    /// @param proxyHelper  - The proxy helper address that manager gnosis factory and proxy wallet factory
    function deployExchange(
        address admin,
        address collateral,
        address ctf,
        address proxyHelper
    ) public returns (address exchange) {
        vm.startBroadcast();

        PredictHubExchange exch = new PredictHubExchange(collateral, ctf, proxyHelper);

        // Grant Auth privileges to the Admin address
        exch.addAdmin(admin);
        exch.addOperator(admin);

        // Revoke the deployer's authorization
        // exch.renounceAdminRole();
        // exch.renounceOperatorRole();

        exchange = address(exch);
    }
}
