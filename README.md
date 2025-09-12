Merkle Airdrop (Foundry)

A simple Merkle Airdrop smart contract implementation with a Foundry test suite.
The project demonstrates how to use a Merkle tree for verifying claims in an airdrop scenario.

Features

ERC20 token for testing (TestToken)
Merkle Airdrop contract with claim verification
Claim window (start & end timestamps)
Admin role with rotation support
Extensive test coverage using Foundry

Project Structure
src/        # Smart contracts
test/       # Test files
foundry.toml
README.md

Getting Started

1. Prerequisites
Foundry

2. Install dependencies
forge install

3. Run tests
forge test -vv

Example

Deploy MerkleAirdrop with:

airdrop = new MerkleAirdrop(
    address(token),
    merkleRoot,
    admin,
    start,
    end
);


Users can then claim with a valid Merkle proof: airdrop.claim(index, account, amount, proof);

License

MIT

