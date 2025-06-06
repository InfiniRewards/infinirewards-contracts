# InfiniRewards Contract Extension Standards and Guidelines (Cairo 2.0)

This document outlines best practices, standards, and guidelines for extending the InfiniRewards contracts, ensuring compatibility with Cairo 2.0.

---

## 🚩 General Guidelines

### 1. Modular Contract Design

* Clearly separate logic into composable components.
* Extend existing InfiniRewards contracts using Cairo 2.0’s trait system for modularity.

### 2. Contract Upgradability

* Maintain consistent use of `upgrade` functions and class hashes.
* Only append new state variables to existing storage to prevent storage collisions.

### 3. Naming Conventions

* Contract names should be clear, concise, and indicative of their purpose.
* Functions should follow verb-noun conventions (e.g., `mint_points`, `redeem_collectible`).

---

## 🚩 Cairo 2.0 Specific Standards

### 1. Traits and Interfaces

* Utilize Cairo 2.0 traits to define interfaces and ensure contracts remain modular and interchangeable.

```rust
#[starknet::interface]
trait IRealEstateAssetToken<TContractState> {
    fn issue_asset(token_id: u256, owner: ContractAddress);
    fn transfer_asset(token_id: u256, from: ContractAddress, to: ContractAddress);
}
```

### 2. Storage Management

* Use `#[storage]` attributes clearly.
* Append new variables carefully to existing contracts.

```rust
#[storage]
struct Storage {
    base: InfiniRewardsCollectible::Storage,
    new_state_variable: u256,
}
```

### 3. Events

* Clearly defined events with indexed parameters for easy off-chain querying.

```rust
#[event]
fn AssetIssued(token_id: u256, owner: ContractAddress);
```

---

## 🚩 Security and Access Control

* Always use Cairo 2.0’s built-in access modifiers (`#[external]`, `#[view]`).
* Implement custom access modifiers carefully, such as `only_owner`.

```rust
#[modifier]
fn only_owner(self: @ContractState) {
    assert(self.caller_address == self.owner, 'Unauthorized access');
    _;
}
```

---

## 🚩 Testing Standards

* Write tests using Starknet’s Cairo 2.0 testing framework.
* Ensure a minimum of 90% critical path test coverage.

```rust
#[test]
fn test_issue_asset() {
    // Test setup and assertions
}
```

---

## 🚩 Documentation Standards

* Each extended contract must have comprehensive documentation in a dedicated README.
* Include purpose, functionality, key methods, events, upgrade paths, and usage examples clearly documented.

---

## 🚩 Deployment & Upgrade Guidelines

* Deploy first on testnets; document class hashes clearly.
* Clearly documented rollback strategies for each upgrade.

---

## 🚩 Regulatory Compliance

* Embed regulatory compliance logic (KYC/AML) directly into smart contracts where applicable.
* Collaborate proactively with regulators for smooth integration.

---

## 🚩 Recommended GitHub Workflow

* Feature branches named clearly: `feature/<feature-name>`
* Structured commit messages (e.g., `feat:`, `fix:`, `docs:`)

---

**Regularly review and update these guidelines as best practices evolve.**
