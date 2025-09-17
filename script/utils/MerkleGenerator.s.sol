// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/StdJson.sol";
import "forge-std/console.sol";

contract MerkleGenerator is Script {
    using stdJson for string;

    struct AirdropData {
        uint256 index;
        address account;
        uint256 amount;
    }

    function getLeaf(uint256 index, address account, uint256 amount) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(index, account, amount));
    }

    function buildMerkleRoot(bytes32[] memory leaves) public pure returns (bytes32 root) {
        bytes32[] memory currentLeaves = leaves;
        while (currentLeaves.length > 1) {
            uint256 n = (currentLeaves.length + 1) / 2;
            bytes32[] memory newLeaves = new bytes32[](n);
            for (uint256 i = 0; i < currentLeaves.length; i += 2) {
                bytes32 left = currentLeaves[i];
                bytes32 right;
                if (i + 1 < currentLeaves.length) {
                    right = currentLeaves[i + 1];
                } else {
                    right = bytes32(0);
                }
                if (left < right) {
                    newLeaves[i / 2] = keccak256(abi.encodePacked(left, right));
                } else {
                    newLeaves[i / 2] = keccak256(abi.encodePacked(right, left));
                }
            }
            currentLeaves = newLeaves;
        }
        if (currentLeaves.length == 1) {
            return currentLeaves[0];
        } else {
            return bytes32(0);
        }
    }

    function buildProof(bytes32[] memory leaves, uint256 index) public pure returns (bytes32[] memory proof) {
        bytes32[] memory currentLeaves = leaves;
        bytes32[] memory proofSteps = new bytes32[](0);
        uint256 n = currentLeaves.length;

        while (n > 1) {
            uint256 nextN = (n + 1) / 2;
            bytes32[] memory newLeaves = new bytes32[](nextN);

            uint256 siblingIndex = (index % 2 == 0) ? index + 1 : index - 1;

            bytes32 siblingHash;

            if (siblingIndex < n) {
                siblingHash = currentLeaves[siblingIndex];
            } else {
                siblingHash = bytes32(0);
            }
            proofSteps = append(proofSteps, siblingHash);

            for (uint256 i = 0; i < n; i += 2) {
                bytes32 left = currentLeaves[i];
                bytes32 right;
                if (i + 1 < n) {
                    right = currentLeaves[i + 1];
                } else {
                    right = bytes32(0);
                }

                if (left < right) {
                    newLeaves[i / 2] = keccak256(abi.encodePacked(left, right));
                } else {
                    newLeaves[i / 2] = keccak256(abi.encodePacked(right, left));
                }
            }
            currentLeaves = newLeaves;
            n = nextN;
            index = index / 2;
        }
        return proofSteps;
    }

    function append(bytes32[] memory arr, bytes32 element) private pure returns (bytes32[] memory) {
        bytes32[] memory newArr = new bytes32[](arr.length + 1);
        for (uint256 i = 0; i < arr.length; i++) {
            newArr[i] = arr[i];
        }
        newArr[arr.length] = element;
        return newArr;
    }

    function getLeavesFromJSON(string memory _jsonContent)
        public
        view
        returns (bytes32[] memory leaves, AirdropData[] memory data)
    {
        string memory claimsArrayPath = ".claims";

        // Temporary storage for a hardcoded number of claims.
        // This is safe due to the break on vm.keyExists failure.
        bytes32[3] memory tempLeaves;
        AirdropData[3] memory tempData;
        uint256 claimsFound = 0;

        for (uint256 i = 0; i < 3; i++) {
            string memory claimPath = string.concat(claimsArrayPath, "[", vm.toString(i), "]");
            if (vm.keyExists(_jsonContent, claimPath)) {
                tempData[i].index = vm.parseJsonUint(_jsonContent, string.concat(claimPath, ".index"));
                tempData[i].account = vm.parseJsonAddress(_jsonContent, string.concat(claimPath, ".address"));
                tempData[i].amount = vm.parseJsonUint(_jsonContent, string.concat(claimPath, ".amount"));

                tempLeaves[i] = getLeaf(tempData[i].index, tempData[i].account, tempData[i].amount);
                claimsFound++;
            } else {
                break;
            }
        }

        leaves = new bytes32[](claimsFound);
        data = new AirdropData[](claimsFound);

        for (uint256 i = 0; i < claimsFound; i++) {
            leaves[i] = tempLeaves[i];
            data[i] = tempData[i];
        }
        return (leaves, data);
    }
}
