## Chainlink CCIP - Proof of Concept

### Description:
This project demonstrates cross-chain message passing using Chainlink CCIP between the Base Chain (Sepolia testnet) and Optimism (Sepolia testnet). It allows sending a wallet address from Optimism to Base and retrieving the associated tier information.

### Prerequisites:
- Node.js (https://nodejs.org/)
- Foundry (https://github.com/foundry-rs/foundry)

### Clone the repository:
```shell
$ git clone git@github.com:skeletordapps/chainlink-ccip-poc.git
```

### Install Foundry dependencies:
```shell
$ foundryup && forge install
```
### Configuration:
Create a ```.env``` file in the project root directory with the following environment variables:
```shell
BASE_SEPOLIA_RPC_URL="https://sepolia.base.org"
OPTIMISM_SEPOLIA_RPC_URL="https://sepolia.optimism.io"

BASE_SEPOLIA_CHAIN_SELECTOR=10344971235874465080
OPTIMISM_SEPOLIA_CHAIN_SELECTOR=5224473277236331295

BASE_SEPOLIA_ROUTER_ADDRESS=0xD3b06cEbF099CE7DA4AcCf578aaebFDBd6e88a93
OPTIMISM_SEPOLIA_ROUTER_ADDRESS=0x114A20A10b43D4115e5aeef7345a1A71d2a60C57

BASE_SEPOLIA_LINK_ADDRESS=0xE4aB69C077896252FAFBD49EFD26B5D171A32410
OPTIMISM_SEPOLIA_LINK_ADDRESS=0xE4aB69C077896252FAFBD49EFD26B5D171A32410

WALLET_A=0x
WALLET_B=0x
WALLET_C=0x
```

**Important:** Replace the placeholder wallet addresses ```(WALLET_A, WALLET_B, WALLET_C)``` with your actual testnet wallet addresses if you intend to use them in the tests.

### Test
```shell
$ forge test && forge coverage
```

### Contracts
```Tier.sol```
Defines tiers on the Base Chain, each with a name, minimum points, and maximum points.

```Points.sol```
Manages a list of wallets and their corresponding points on the Base Chain. This contract is used to determine the tier associated with a wallet's points.

```Ask.sol```
Deployed on Optimism, this contract facilitates sending a wallet address to the Base Chain to retrieve tier information.

```Answer.sol```
Receives requests from other chains (in this case, Optimism) to check the tier of a specified wallet address on the Base Chain.

