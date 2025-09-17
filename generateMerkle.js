import fs from "fs";
import { keccak256, toUtf8Bytes, AbiCoder } from "ethers";


// Read whitelist
const whitelist = JSON.parse(fs.readFileSync("./whitelist.json", "utf8"));

// Use AbiCoder to match Solidity's abi.encodePacked
const coder = AbiCoder.defaultAbiCoder();

// Adjusted function to match Solidity's abi.encodePacked logic
function getLeaf(index, account, amount) {
    // abi.encodePacked(uint256, address, uint256)
    return keccak256(coder.encode(["uint256", "address", "uint256"], [index, account, amount]));
}

// Build Merkle tree (matches solidity ordering: smaller first)
function buildMerkleTree(leaves) {
    let tree = [leaves];
    while (tree[tree.length - 1].length > 1) {
        const layer = tree[tree.length - 1];
        const nextLayer = [];
        for (let i = 0; i < layer.length; i += 2) {
            if (i + 1 < layer.length) {
                const left = layer[i];
                const right = layer[i + 1];
                
		const combined = left < right ? `${left}${right.slice(2)}` : `${right}${left.slice(2)}`;
                nextLayer.push(keccak256(combined));
            } else {
                nextLayer.push(layer[i]);
            }
        }
        tree.push(nextLayer);
    }
    return tree;
}

// Generate proof for a leaf
function getProof(tree, index) {
    const proof = [];
    for (let i = 0; i < tree.length - 1; i++) {
        const layer = tree[i];
        const isRightNode = index % 2;
        const pairIndex = isRightNode ? index - 1 : index + 1;
        if (pairIndex < layer.length) proof.push(layer[pairIndex]);
        index = Math.floor(index / 2);
    }
    return proof;
}

// Build leaves
const leaves = whitelist.map((entry, i) => getLeaf(i, entry.address, entry.amount));

// Build tree
const tree = buildMerkleTree(leaves);

// Declare and assign merkleRoot after the tree is built 
const merkleRoot = tree[tree.length - 1][0];

// Build claim objects
const claims = whitelist.map((entry, i) => ({
    index: i,
    address: entry.address,
    amount: entry.amount.toString(),
    proof: getProof(tree, i)
}));

// Save data to a single JSON file
const outputData = {
    merkleRoot: merkleRoot,
    claims: claims,
};

fs.writeFileSync("./merkleData.json", JSON.stringify(outputData, null, 2));

console.log("Merkle root:", merkleRoot);
console.log("Merkle data generated and saved to merkleData.json");

