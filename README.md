# 🌿 Merkle Airdrop (Foundry)

![Solidity](https://img.shields.io/badge/Solidity-0.8.20+-blue.svg)
![Foundry](https://img.shields.io/badge/Framework-Foundry-orange.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

A compact, auditable **Merkle Airdrop system** built with [Foundry](https://book.getfoundry.sh/).  
It demonstrates end-to-end airdrop distribution — from JSON claim data to Merkle root generation and on-chain claim verification.

---

## 🧠 Overview

This project provides:
- **Off-chain Merkle generation** using Solidity scripts  
- **On-chain proof verification** for token claims  
- **Automated deployment** to Sepolia via Foundry  

Main components:
1. `MerkleGenerator.s.sol` — parses JSON claim data, builds leaves & Merkle root  
2. `MerkleAirdrop.sol` — contract verifying proofs and handling secure token claims  
3. `DeployMerkleAirdropSepolia.s.sol` — broadcasts deployment with Foundry scripts  

---

## ⚙️ Structure
src/
├─ MerkleAirdrop.sol
└─ MockERC20.sol
script/
├─ DeployMerkleAirdropSepolia.s.sol
└─ utils/MerkleGenerator.s.sol
test/
└─ MerkleAirdropTest.t.sol
airdrop.json

## 🚀 Quick Start
```bash
forge build
forge script script/DeployMerkleAirdropSepolia.s.sol --rpc-url $RPC_URL_SEPOLIA --broadcast

🪂 Automatically:
Reads airdrop.json
Generates Merkle root
Deploys contracts & initializes airdrop

🧪 Testing
Covers:
✅ Leaf & root generation
✅ Proof verification
✅ Double-claim protection

Run:
bash
forge test

🧾 Example JSON
json
{
  "claims": [
    { "index": 0, "address": "0x1111...", "amount": 1000 },
    { "index": 1, "address": "0x2222...", "amount": 2000 }
  ]
}

🔗 Built With
Solidity ^0.8.20

Foundry + Forge Std

OpenZeppelin ERC-20

👤 Author
Olaomoju Ola-Taiwo
🔗 GitHub

📜 MIT License

yaml
Copy code
