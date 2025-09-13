// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "../src/MerkleAirdrop.sol";
import "../src/TestToken.sol";

contract MerkleAirdropFullClaimTest is Test {
    MerkleAirdrop airdrop;
    TestToken token;

    // Whitelist addresses
    address[] whitelistAddresses = [
        address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266),
        address(0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65),
        address(0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc)
    ];

    // Claim amounts
    uint256[] whitelistAmounts = [1000 ether, 2000 ether, 1500 ether];

    bytes32 merkleRoot;
    mapping(address => bytes32[]) internal proofs;

    function setUp() public {
        // Deploy TestToken
        token = new TestToken("TestToken", "TTK", 1_000_000 ether);

        // Build Merkle tree
        bytes32[] memory leaves = new bytes32[](whitelistAddresses.length);
        for (uint256 i = 0; i < whitelistAddresses.length; i++) {
            leaves[i] = getLeaf(i, whitelistAddresses[i], whitelistAmounts[i]);
        }

        // Compute Merkle root
        merkleRoot = buildMerkleRoot(leaves);

        // Deploy MerkleAirdrop with computed root
        airdrop =
            new MerkleAirdrop(address(token), merkleRoot, address(this), block.timestamp, block.timestamp + 1 days);

        // Fund the airdrop
        uint256 total = 0;
        for (uint256 i = 0; i < whitelistAmounts.length; i++) {
            total += whitelistAmounts[i];
        }
        token.transfer(address(airdrop), total);

        // Store proofs for each user
        for (uint256 i = 0; i < whitelistAddresses.length; i++) {
            proofs[whitelistAddresses[i]] = buildProof(leaves, i);
        }
    }

    function testFullClaim() public {
        for (uint256 i = 0; i < whitelistAddresses.length; i++) {
            vm.prank(whitelistAddresses[i]);
            airdrop.claim(i, whitelistAddresses[i], whitelistAmounts[i], proofs[whitelistAddresses[i]]);

            assertEq(token.balanceOf(whitelistAddresses[i]), whitelistAmounts[i]);
        }
    }

    // -----------------
    // Helpers
    // -----------------

    function getLeaf(uint256 index, address account, uint256 amount) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(index, account, amount));
    }

    function buildMerkleRoot(bytes32[] memory leaves) internal pure returns (bytes32 root) {
        while (leaves.length > 1) {
            uint256 n = (leaves.length + 1) / 2;
            bytes32[] memory newLeaves = new bytes32[](n);
            for (uint256 i = 0; i < leaves.length; i += 2) {
                if (i + 1 < leaves.length) {
                    if (leaves[i] < leaves[i + 1]) {
                        newLeaves[i / 2] = keccak256(abi.encodePacked(leaves[i], leaves[i + 1]));
                    } else {
                        newLeaves[i / 2] = keccak256(abi.encodePacked(leaves[i + 1], leaves[i]));
                    }
                } else {
                    newLeaves[i / 2] = leaves[i];
                }
            }
            leaves = newLeaves;
        }
        return leaves[0];
    }

    function buildProof(bytes32[] memory leaves, uint256 index) internal pure returns (bytes32[] memory proof) {
        uint256 n = leaves.length;
        proof = new bytes32[](0);
        while (n > 1) {
            uint256 nextN = (n + 1) / 2;
            bytes32[] memory newLeaves = new bytes32[](nextN);
            for (uint256 i = 0; i < n; i += 2) {
                if (i + 1 < n) {
                    bytes32 left = leaves[i];
                    bytes32 right = leaves[i + 1];
                    if (i == index || i + 1 == index) {
                        bytes32 sibling = (i == index) ? right : left;
                        proof = appendProof(proof, sibling);
                        index = i / 2;
                    }
                    newLeaves[i / 2] = (left < right)
                        ? keccak256(abi.encodePacked(left, right))
                        : keccak256(abi.encodePacked(right, left));
                } else {
                    newLeaves[i / 2] = leaves[i];
                    if (i == index) {
                        index = i / 2;
                    }
                }
            }
            leaves = newLeaves;
            n = nextN;
        }
    } // The missing closing brace was added here.

    function appendProof(bytes32[] memory proof, bytes32 node) internal pure returns (bytes32[] memory newProof) {
        newProof = new bytes32[](proof.length + 1);
        for (uint256 i = 0; i < proof.length; i++) {
            newProof[i] = proof[i];
        }
        newProof[proof.length] = node;
    }
}
