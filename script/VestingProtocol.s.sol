// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {VestingProtocol} from "src/VestingProtocol.sol";

contract DeployVestingProtocol is Script {
    function run() public returns (VestingProtocol) {
        // change with real addresses/values before deploy
        address beneficiary = 0x0000000000000000000000000000000000000000;
        address token = 0x0000000000000000000000000000000000000000;
        uint256 duration = 365 days;
        uint256 totalAmount = 1000 ether;
        vm.startBroadcast();
        VestingProtocol vesting = new VestingProtocol(beneficiary, token, duration, totalAmount);
        vm.stopBroadcast();

        return vesting;
    }
}