// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { Script } from "forge-std/Script.sol";
import { UmaAdapter } from "markets/UmaAdapter.sol";
import { UmaAdapter } from "markets/UmaAdapter.sol";
import { WhitelistDisputerEscalationManager } from "@uma/core/contracts/optimistic-oracle-v3/implementation/escalation-manager/WhitelistDisputerEscalationManager.sol";
import { console2 as console } from "forge-std/Test.sol";

/// @title ExchangeDeployment
/// @notice Script to deploy the CTF Exchange
/// @author PredictHub
contract AdapterDeployment is Script {
    /// @notice Deploys the Uma Adapter contract
    /// @param finder        - The finder
    /// @param oov3   - The oov3
    function deployAdapter(address finder, address oov3) public returns (address umaDatapter, address disputerManager) {
        vm.startBroadcast();
        WhitelistDisputerEscalationManager disputerManagerContract = new WhitelistDisputerEscalationManager(oov3);
        console.log("Deployed disputerManager at %s", address(disputerManagerContract));
        UmaAdapter umaAdapterContract = new UmaAdapter(finder, oov3);
        console.log("Deployed adapter at %s", address(umaAdapterContract));
        // Grant Auth privileges to the Admin address
        umaAdapterContract.setWhitelistDisputerManager(address(disputerManagerContract));

        umaDatapter = address(umaAdapterContract);
        disputerManager = address(disputerManagerContract);
    }
}
