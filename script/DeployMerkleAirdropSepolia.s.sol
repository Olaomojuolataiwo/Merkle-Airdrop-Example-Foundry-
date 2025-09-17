// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "forge-std/StdJson.sol";
import "../src/MerkleAirdrop.sol"; // Corrected import
import "../src/TestToken.sol"; // Corrected import
import "./utils/MerkleGenerator.s.sol";

contract DeployMerkleAirdropSepolia is Script {
    using stdJson for string;

    function run() external {
        // === Load environment variables from .env first ===
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        string memory json = vm.envString("WHITELIST_JSON");

        // === Dynamically generate the Merkle root ===
        MerkleGenerator generator = new MerkleGenerator();
        (bytes32[] memory leaves, ) = generator.getLeavesFromJSON(json);
        bytes32 merkleRoot = generator.buildMerkleRoot(leaves);

        // === Start broadcasting the transactions to the network ===
        vm.startBroadcast(deployerPrivateKey);

        // === Deploy TestToken ===
        TestToken token = new TestToken("Test Token", "TTK", 1_000_000 * 10 ** 18);

        // === Configure Merkle Airdrop ===
        uint256 startTime = block.timestamp + 5 minutes;
        uint256 endTime = block.timestamp + 7 days;

        MerkleAirdrop airdrop = new MerkleAirdrop(
            address(token),
            merkleRoot,
            deployer, // admin
            startTime,
            endTime
        );

        // === Fund Airdrop ===
        token.mint(address(airdrop), 500_000 * 10 ** 18);

        // === Stop broadcasting ===
        vm.stopBroadcast();

        // === Logs (for post-transaction review) ===
        console.log("Deployer:", deployer);
        console.log("Token deployed at:", address(token));
        console.log("MerkleAirdrop deployed at:", address(airdrop));
        console.logBytes32(merkleRoot);
        console.log("Start:", startTime);
        console.log("End:", endTime);
    }
}
