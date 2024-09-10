## Chainlink CCIP - Proof of Concept

Send and receive messages crosschain - Base <> Optimism (testnets)

### Clone
```shell
$ git clone git@github.com:skeletordapps/chainlink-ccip-poc.git
```

### Run
```shell
$ foundryup && forge install
```

### Create .env file
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

### Test
```shell
$ forge test && forge coverage
```

### Contracts
- ***Tier.sol:*** used on base testnet as a list of tiers with name and min/max points.
- ***Points.sol:*** used on base testnet as a list of wallets and it's points to be compared on each tier in order to know the correct tier.
- ***Ask.sol:*** used on optimism to send a wallet and obtain the tier in base network
- ***Answer.sol:*** receives the wallet to be checked from other chain
