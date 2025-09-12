// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MerkleAirdrop.sol";
import "../src/TestToken.sol";

contract MerkleAirdropTest is Test {
    MerkleAirdrop public airdrop;
    TestToken public token;

    address public admin = address(0xA1);
    address public newAdmin = address(0xA2);
    address public alice = address(0xB1);
    address public bob = address(0xB2);

    uint256 public amountA = 100 ether;
    uint256 public amountB = 200 ether;

    bytes32 public leafA;
    bytes32 public leafB;
    bytes32 public root;

    function setUp() public {
        // deploy test token (mint to this test contract)
        token = new TestToken("Test", "TST", 1_000_000 ether);

        // create a simple 2-leaf Merkle tree (no sorting)
        leafA = keccak256(abi.encodePacked(uint256(0), alice, amountA));
        leafB = keccak256(abi.encodePacked(uint256(1), bob, amountB));
        root = keccak256(abi.encodePacked(leafA, leafB));

        // deploy MerkleAirdrop: owner = this test contract
        airdrop = new MerkleAirdrop(address(token), root, admin, 0, 0);

        // fund the airdrop contract
        token.transfer(address(airdrop), amountA + amountB);
    }

    // ======== TESTS ========

    function testClaimSucceedsWithValidProof() public {

	// 1. Set the claim window to include the current block timestamp
        uint256 start = block.timestamp - 1; // already started
        uint256 end = block.timestamp + 1 days; // ends in the future
        airdrop = new MerkleAirdrop(address(token), root, admin, start, end);

        // 2. Fund airdrop with tokens
        token.mint(address(airdrop), amountA);


	// 3. Allocate proof array
        bytes32[] memory proof = new bytes32[](1); 
	proof[0] = leafB; // sibling
	
	// 4. Warp time to ensure we are inside the claim window
        vm.warp(start + 1);

	// 5. Call claim
	vm.prank(alice);
        airdrop.claim(0, alice, amountA, proof);

	// 6. Assertions
        assertEq(token.balanceOf(alice), amountA);
        assertTrue(airdrop.isClaimed(0));
    }

    function testRejectedIfAlreadyClaimed() public {
        
	// 1. Set the claim window
        uint256 start = block.timestamp - 1;
        uint256 end = block.timestamp + 1 days;
        airdrop = new MerkleAirdrop(address(token), root, admin, start, end);

	// 2. Fund airdrop with tokens
        token.mint(address(airdrop), amountA);

        // 3. Allocate proof array
        bytes32[] memory proof = new bytes32[](1); 
	proof[0] = leafB;

	// 4. Warp time inside claim window
        vm.warp(start + 1);

        // 5. First claim succeeds
        vm.prank(alice);
        airdrop.claim(0, alice, amountA, proof);

        // 6. Second claim reverts
	vm.prank(alice);
        vm.expectRevert(bytes("MerkleAirdrop: already claimed"));
        airdrop.claim(0, alice, amountA, proof);
    }

    function testAdminRotationWorks() public {
        bytes32 newRoot = keccak256(abi.encodePacked(uint256(9)));

        // old admin can update root
        vm.prank(admin);
        airdrop.updateMerkleRoot(newRoot);
        assertEq(airdrop.merkleRoot(), newRoot);

        // owner rotates admin
        airdrop.rotateAdmin(newAdmin);

        // old admin no longer can update
        vm.prank(admin);
        vm.expectRevert(bytes("MerkleAirdrop: not admin or owner"));
        airdrop.updateMerkleRoot(root);

        // new admin can update
        vm.prank(newAdmin);
        airdrop.updateMerkleRoot(root);
        assertEq(airdrop.merkleRoot(), root);
    }
}
