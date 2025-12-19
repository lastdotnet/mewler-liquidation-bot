// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {EVaultGateway} from "contracts/EVaultGateway.sol";
import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";

contract DeployEVaultGateway is Script {
    function run() public {
        vm.startBroadcast(vm.envUint("DEPLOYER_PRIVATE_KEY"));

        EVaultGateway eVaultGateway = new EVaultGateway();
        
        vm.stopBroadcast();

        console2.log("EVaultGateway: ", address(eVaultGateway));
    }
}