// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/MerkleAirdrop.sol";
import "../src/TestToken.sol";
import "forge-std/StdJson.sol";

contract ClaimMerkleAirdropSepolia is Script {
    using stdJson for string;

    function run() external {
        uint256 claimerPrivateKey = vm.envUint("PRIVATE_KEY");
        address claimerAddress = vm.addr(claimerPrivateKey);

        // === Configure deployed contracts ===
        address merkleAirdropAddr = address(0x9815034C4F39E4e0FE15112469a53f4463375836);
        address tokenAddr = address(0x6A14603B408620778c3B17C768925501b64684A0);

        MerkleAirdrop airdrop = MerkleAirdrop(merkleAirdropAddr);
        TestToken token = TestToken(tokenAddr);

        // === Load Merkle data from an environment variable ===
        string memory json = vm.envString("WHITELIST_JSON");

        // === Find the claim for the current address ===
        uint256 index;
        uint256 amount;
        string[] memory proofStrings;

        bool found = false;

        // Iterate up to a small number of checks.
        // The loop is safe as it will break when no more claims are found.
        for (uint256 i = 0; i < 5; i++) {
            // Check if the address exists at this index before attempting to read it
            string memory claimPath = string.concat(".claims[", vm.toString(i), "].address");

            // This is the correct way to handle optional JSON values
            if (vm.parseJson(json, claimPath).length > 0) {
                address claimantFromJSON = json.readAddress(claimPath);
                if (claimantFromJSON == claimerAddress) {
                    index = json.readUint(string.concat(".claims[", vm.toString(i), "].index"));
                    amount = json.readUint(string.concat(".claims[", vm.toString(i), "].amount"));
                    proofStrings = json.readStringArray(string.concat(".claims[", vm.toString(i), "].proof"));
                    found = true;
                    break;
                }
            } else {
                // Break out of the loop if the path doesn't exist
                break;
            }
        }

        require(found, "Claim: No claim found for this address");

        // Build proof array dynamically
        bytes32[] memory proof = new bytes32[](proofStrings.length);
        for (uint256 i = 0; i < proofStrings.length; i++) {
            proof[i] = bytes32(vm.parseBytes32(proofStrings[i]));
        }

        vm.startBroadcast(claimerPrivateKey);

        // === Attempt claim ===
        airdrop.claim(index, claimerAddress, amount, proof);

        vm.stopBroadcast();
        console.log("Claim executed for:", claimerAddress);
        console.log("New token balance:", token.balanceOf(claimerAddress));
    }
}
