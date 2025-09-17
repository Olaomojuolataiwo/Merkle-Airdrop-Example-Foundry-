// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/MerkleAirdrop.sol";
import "../src/TestToken.sol";

contract DeployMerkleAirdrop is Script {
    function run() external {
        // --- Load environment variables ---
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address token = vm.envAddress("TOKEN_ADDRESS");
        bytes32 merkleRoot = vm.envBytes32("MERKLE_ROOT");
        uint256 fundAmount = vm.envUint("FUND_AMOUNT") * 1e18; // in wei

        // --- Broadcast from deployer ---
        vm.startBroadcast(deployerPrivateKey);

        address admin = vm.addr(deployerPrivateKey);

        // Set start/end times (for example, now -> +30 days)
        uint256 startTime = block.timestamp;
        uint256 endTime = block.timestamp + 30 days;

        // --- Deploy MerkleAirdrop ---
        MerkleAirdrop airdrop = new MerkleAirdrop(token, merkleRoot, admin, startTime, endTime);

        console2.log(" MerkleAirdrop deployed at:", address(airdrop));

        // --- Fund the airdrop contract ---
        TestToken(token).transfer(address(airdrop), fundAmount);
        console2.log(" Funded MerkleAirdrop with", fundAmount, "tokens");

        vm.stopBroadcast();
    }
}
