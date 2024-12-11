# InfiniRewards Smart Contracts

A comprehensive rewards system built on StarkNet that enables merchants to create and manage loyalty programs using points and collectibles.

## Overview

InfiniRewards is a modular smart contract system that allows:
- Merchants to create and manage their own loyalty points
- Users to earn and spend points across different merchants
- Creation and management of collectible NFTs (ERC-1155)
- Secure account abstraction for both users and merchants

## Contract Architecture

The system consists of several core contracts:

### InfiniRewardsFactory
- Central factory contract for deploying and managing the ecosystem
- Creates user accounts, merchant accounts, points contracts, and collectible contracts
- Maintains registry of all deployed contracts

### InfiniRewardsPoints
- ERC-20 compatible points token
- Customizable name, symbol, and decimals
- Pausable and upgradeable functionality
- Owned and managed by merchant accounts

### InfiniRewardsCollectible
- ERC-1155 compatible NFT contract
- Supports multiple collectible types per merchant
- Configurable pricing in merchant's points
- Metadata and supply management

### Account Contracts
- Separate account implementations for users and merchants
- Built on OpenZeppelin account abstractions
- Secure transaction validation and execution

## Development

### Prerequisites
- [Scarb](https://docs.swmansion.com/scarb)
- Node.js & npm/yarn
- StarkNet Devnet (for local development)

### Setup
1. Clone the repository
2. Install dependencies:
```bash
npm install
cd contracts && scarb build
```

### Testing
Run the test suite:
```bash
npm run test
```

### Local Deployment
1. Start local devnet:
```bash
npm run chain
```

2. Deploy contracts:
```bash
npm run deploy
```

For a fresh deployment:
```bash
npm run deploy:reset
```

## Contract Addresses

The deployed contract addresses can be found in `outputs/contracts/deployedContracts.ts`. This file is automatically generated during deployment.


