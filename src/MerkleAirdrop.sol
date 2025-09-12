// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract MerkleAirdrop is ReentrancyGuard {
    ERC20 public immutable token;
    bytes32 public merkleRoot;
    address public owner;
    address public admin;

    uint256 public startTime;
    uint256 public endTime;

    mapping(uint256 => bool) public isClaimed;

    event Claimed(uint256 indexed index, address indexed account, uint256 amount);
    event MerkleRootUpdated(bytes32 newRoot);
    event AdminRotated(address newAdmin);
    event WindowUpdated(uint256 newStart, uint256 newEnd);
    event Withdrawn(address recipient, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "MerkleAirdrop: not owner");
        _;
    }

    modifier onlyAdminOrOwner() {
        require(msg.sender == admin || msg.sender == owner, "MerkleAirdrop: not admin or owner");
        _;
    }

    modifier claimWindow() {
        require(block.timestamp >= startTime, "MerkleAirdrop: too early");
        require(block.timestamp <= endTime, "MerkleAirdrop: too late");
        _;
    }

    constructor(
        address _token,
        bytes32 _merkleRoot,
        address _admin,
        uint256 _startTime,
        uint256 _endTime
    ) {
        token = ERC20(_token);
        merkleRoot = _merkleRoot;
        admin = _admin;
        owner = msg.sender;
        startTime = _startTime;
        endTime = _endTime;
    }

    function claim(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata proof
    ) external nonReentrant claimWindow {
        require(!isClaimed[index], "MerkleAirdrop: already claimed");
        require(_verify(index, account, amount, proof), "MerkleAirdrop: invalid proof");

        isClaimed[index] = true;
        token.transfer(account, amount);

        emit Claimed(index, account, amount);
    }

    function updateMerkleRoot(bytes32 newRoot) external onlyAdminOrOwner {
        merkleRoot = newRoot;
        emit MerkleRootUpdated(newRoot);
    }

    function rotateAdmin(address newAdmin) external onlyOwner {
        admin = newAdmin;
        emit AdminRotated(newAdmin);
    }

    function updateWindow(uint256 _startTime, uint256 _endTime) external onlyOwner {
        startTime = _startTime;
        endTime = _endTime;
        emit WindowUpdated(_startTime, _endTime);
    }

    function withdrawRemaining(address recipient) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(recipient, balance);
        emit Withdrawn(recipient, balance);
    }

    // ======== INTERNAL ========
    function _verify(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata proof
    ) internal view returns (bool) {
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        bytes32 computedHash = node;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash < proofElement) {
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        return computedHash == merkleRoot;
    }
}
