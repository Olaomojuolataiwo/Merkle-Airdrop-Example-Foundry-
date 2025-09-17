// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/TestToken.sol";

contract DeployTestToken is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy with 1 million tokens (18 decimals)
        TestToken token = new TestToken("TestToken", "TTK", 1_000_000 ether);

        console.log("TestToken deployed at:", address(token));

        vm.stopBroadcast();
    }
}
