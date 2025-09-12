// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Test.sol";
import "../src/MerkleAirdrop.sol";
import "../src/TestToken.sol";

contract MerkleAirdropAdditionalTest is Test {
    MerkleAirdrop public airdrop;
    TestToken public token;
    address public admin;
    bytes32 public root;

    address public alice = address(0x1);
    address public bob = address(0x2);

    uint256 public amountA = 100 ether;
    uint256 public amountB = 200 ether;
    uint256 public start;
    uint256 public end;

    // We will build the leaves correctly inside setUp
    bytes32 public leafA;
    bytes32 public leafB;

    function setUp() public {
        // Deploy token with initial supply to this test contract
        token = new TestToken("TestToken", "TST", 1_000_000 ether);
        admin = address(this);

        // Define leaves with a proper structure including the index
        leafA = keccak256(abi.encodePacked(uint256(0), alice, amountA));
        leafB = keccak256(abi.encodePacked(uint256(1), bob, amountB));

        // Proper Merkle root: hash the concatenation of sorted leaves
        bytes32 node;
        if (leafA < leafB) {
            node = keccak256(abi.encodePacked(leafA, leafB));
        } else {
            node = keccak256(abi.encodePacked(leafB, leafA));
        }
        root = node;

        // Claim window
        start = block.timestamp;
        end   = block.timestamp + 1 days;

        // Deploy airdrop
        airdrop = new MerkleAirdrop(address(token), root, admin, start, end);

        // Fund airdrop
        token.mint(address(airdrop), amountA + amountB);
    }

    function testClaimDuplicate() public {
        // Since leafA is less than leafB, the proof for leafA is leafB.
        bytes32[] memory proof = new bytes32[](1);
        proof[0] = leafB;

        vm.warp(start + 1);
        vm.prank(alice);
        airdrop.claim(0, alice, amountA, proof);

        // Attempt to claim again
        vm.prank(alice);
        vm.expectRevert(bytes("MerkleAirdrop: already claimed"));
        airdrop.claim(0, alice, amountA, proof);
    }

    function testClaimBeforeStart() public {
        // Create a future claim window
        uint256 futureStart = block.timestamp + 1 days;
        uint256 futureEnd = futureStart + 1 days;
        MerkleAirdrop futureAirdrop = new MerkleAirdrop(address(token), root, admin, futureStart, futureEnd);

        // Fund the new airdrop
        token.mint(address(futureAirdrop), amountA + amountB);

        // Try claiming before start
        bytes32[] memory proof = new bytes32[](1);
        proof[0] = leafB;

        vm.expectRevert("MerkleAirdrop: too early");
        futureAirdrop.claim(0, alice, amountA, proof);
    }

    function testClaimAfterEnd() public {
        // Since leafA is less than leafB, the proof for leafA is leafB.
        bytes32[] memory proof = new bytes32[](1);
        proof[0] = leafB;

        vm.warp(end + 1); // after claim window
        vm.prank(alice);
        vm.expectRevert(bytes("MerkleAirdrop: too late"));
        airdrop.claim(0, alice, amountA, proof);
    }

    function testClaimWithInvalidProof() public {
        bytes32[] memory proof = new bytes32[](1);
        proof[0] = keccak256("invalid");

        vm.warp(start + 1);
        vm.prank(alice);
        vm.expectRevert(bytes("MerkleAirdrop: invalid proof"));
        airdrop.claim(0, alice, amountA, proof);
    }

    function testClaimOutOfRangeIndex() public {
        bytes32[] memory proof = new bytes32[](1);
        proof[0] = leafB;

        // Try to claim with an invalid index (e.g., index 2)
        // The leaf will be keccak256(abi.encodePacked(uint256(2), alice, amountA))
        // This will not match any leaf in the Merkle tree, causing the invalid proof error.
        vm.warp(start + 1);
        vm.prank(alice);
        vm.expectRevert(bytes("MerkleAirdrop: invalid proof"));
        airdrop.claim(2, alice, amountA, proof);
    }
}
