// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/StdJson.sol";
import "forge-std/console.sol";
import "../src/MerkleAirdrop.sol";
import "../src/TestToken.sol";
import "./utils/MerkleGenerator.s.sol";

contract ClaimMerkleAirdropSepolia is Script {
    using stdJson for string;

    function run() external {
        uint256 fundedPrivateKey = vm.envUint("FUNDED_PRIVATE_KEY");
	uint256 claimerPrivateKey = vm.envUint("PRIVATE_KEY");
        address claimer = vm.addr(claimerPrivateKey);
        string memory json = vm.envString("WHITELIST_JSON");

        // Hardcode the deployed contract addresses
        address merkleAirdropAddr = address(0x12F7dD127D66D3B549CbEfc8Fd0157606a5EDa32);
        address tokenAddr = address(0x074bc223a9C9efab5301cC4F90FD54483d03EF53);

        // Instantiate the MerkleGenerator to use its functions
        MerkleGenerator generator = new MerkleGenerator();

        // 1. Get all leaves and the claimant's data from the JSON
        (bytes32[] memory leaves, MerkleGenerator.AirdropData[] memory data) = generator.getLeavesFromJSON(json);

        uint256 claimantIndex;
        uint256 claimantAmount;
        bool found = false;

        // 2. Find the claimant's specific data in the parsed array
        for (uint256 i = 0; i < data.length; i++) {
            if (data[i].account == claimer) {
                claimantIndex = data[i].index;
                claimantAmount = data[i].amount;
                found = true;
                break;
            }
        }
        require(found, "Claimant not found in the whitelist.");
	
	vm.startBroadcast(fundedPrivateKey);

        // 3. Dynamically generate the Merkle proof for the claimant
        bytes32[] memory proof = generator.buildProof(leaves, claimantIndex);

        // Get the deployed contracts
        MerkleAirdrop airdrop = MerkleAirdrop(merkleAirdropAddr);
        TestToken token = TestToken(tokenAddr);

        

        // 4. Claim the airdrop using the dynamically generated proof
        airdrop.claim(claimantIndex, claimer, claimantAmount, proof);

            }
}
