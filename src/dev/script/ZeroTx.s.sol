// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { Json } from "dev/util/Json.sol";
import { Script } from "forge-std/Script.sol";

contract ZeroTx is Script {
    function run() public {
        vm.startBroadcast();
        payable(address(this)).transfer(0);
    }
}
