# InfiniRewards Contracts Documentation

This document provides a comprehensive overview of the InfiniRewards contract system, including all methods, their input parameters, and return values.

## Table of Contents

1. [InfiniRewardsFactory](#infinirewardsfactory)
2. [InfiniRewardsPoints](#infinirewardspoints)
3. [InfiniRewardsCollectible](#infinirewardscollectible)
4. [InfiniRewardsUserAccount](#infinirewardsuseraccount)
5. [InfiniRewardsMerchantAccount](#infinirewardsmerchantaccount)

## InfiniRewardsFactory

The InfiniRewardsFactory contract is responsible for deploying and managing user accounts, merchant accounts, points contracts, and collectible contracts.

### Methods

#### pause
**Type**: Write  
**Description**: Pauses the contract, preventing certain operations.  
**Input Parameters**: None  
**Output**: None  
**Access Control**: Only owner  

#### unpause
**Type**: Write  
**Description**: Unpauses the contract, allowing operations to resume.  
**Input Parameters**: None  
**Output**: None  
**Access Control**: Only owner  

#### create_user
**Type**: Write  
**Description**: Creates a new user account.  
**Input Parameters**:
- `public_key` (felt252): The public key for the user account
- `metadata` (ByteArray): Additional metadata for the user account

**Output**:
- `ContractAddress`: The address of the newly created user account

#### create_merchant_contract
**Type**: Write  
**Description**: Creates a new merchant account and associated points contract.  
**Input Parameters**:
- `public_key` (felt252): The public key for the merchant account
- `metadata` (ByteArray): Additional metadata for the merchant account
- `name` (ByteArray): Name for the points contract
- `symbol` (ByteArray): Symbol for the points contract
- `decimals` (u8): Decimal places for the points contract

**Output**:
- `(ContractAddress, ContractAddress)`: Tuple containing the merchant account address and points contract address

#### create_points_contract
**Type**: Write  
**Description**: Creates a new points contract for an existing merchant.  
**Input Parameters**:
- `name` (ByteArray): Name for the points contract
- `symbol` (ByteArray): Symbol for the points contract
- `metadata` (ByteArray): Additional metadata for the points contract
- `decimals` (u8): Decimal places for the points contract

**Output**:
- `ContractAddress`: The address of the newly created points contract

#### create_collectible_contract
**Type**: Write  
**Description**: Creates a new collectible contract for an existing merchant.  
**Input Parameters**:
- `name` (ByteArray): Name for the collectible contract
- `metadata` (ByteArray): Additional metadata for the collectible contract

**Output**:
- `ContractAddress`: The address of the newly created collectible contract

#### get_user_class_hash
**Type**: Read  
**Description**: Gets the class hash for user accounts.  
**Input Parameters**: None  
**Output**:
- `ClassHash`: The class hash for user accounts

#### set_user_class_hash
**Type**: Write  
**Description**: Sets the class hash for user accounts.  
**Input Parameters**:
- `class_hash` (ClassHash): The new class hash for user accounts

**Output**: None  
**Access Control**: Only owner  

#### get_merchant_class_hash
**Type**: Read  
**Description**: Gets the class hash for merchant accounts.  
**Input Parameters**: None  
**Output**:
- `ClassHash`: The class hash for merchant accounts

#### set_merchant_class_hash
**Type**: Write  
**Description**: Sets the class hash for merchant accounts.  
**Input Parameters**:
- `class_hash` (ClassHash): The new class hash for merchant accounts

**Output**: None  
**Access Control**: Only owner  

#### get_points_class_hash
**Type**: Read  
**Description**: Gets the class hash for points contracts.  
**Input Parameters**: None  
**Output**:
- `ClassHash`: The class hash for points contracts

#### set_points_class_hash
**Type**: Write  
**Description**: Sets the class hash for points contracts.  
**Input Parameters**:
- `class_hash` (ClassHash): The new class hash for points contracts

**Output**: None  
**Access Control**: Only owner  

#### get_collectible_class_hash
**Type**: Read  
**Description**: Gets the class hash for collectible contracts.  
**Input Parameters**: None  
**Output**:
- `ClassHash`: The class hash for collectible contracts

#### set_collectible_class_hash
**Type**: Write  
**Description**: Sets the class hash for collectible contracts.  
**Input Parameters**:
- `class_hash` (ClassHash): The new class hash for collectible contracts

**Output**: None  
**Access Control**: Only owner  

#### upgrade
**Type**: Write  
**Description**: Upgrades the contract to a new implementation.  
**Input Parameters**:
- `new_class_hash` (ClassHash): The class hash of the new implementation

**Output**: None  
**Access Control**: Only owner  

## InfiniRewardsPoints

The InfiniRewardsPoints contract is an ERC20-compatible token used for loyalty points.

### Methods

#### pause
**Type**: Write  
**Description**: Pauses the contract, preventing certain operations.  
**Input Parameters**: None  
**Output**: None  
**Access Control**: Only owner  

#### unpause
**Type**: Write  
**Description**: Unpauses the contract, allowing operations to resume.  
**Input Parameters**: None  
**Output**: None  
**Access Control**: Only owner  

#### burn
**Type**: Write  
**Description**: Burns (destroys) a specified amount of points from the caller's balance.  
**Input Parameters**:
- `value` (u256): The amount of points to burn

**Output**: None  

#### mint
**Type**: Write  
**Description**: Mints (creates) a specified amount of points to a recipient.  
**Input Parameters**:
- `recipient` (ContractAddress): The address to receive the minted points
- `amount` (u256): The amount of points to mint

**Output**: None  
**Access Control**: Only owner  

#### update_metadata
**Type**: Write  
**Description**: Updates the metadata for the points contract.  
**Input Parameters**:
- `metadata` (ByteArray): The new metadata

**Output**: None  
**Access Control**: Only owner  

#### get_details
**Type**: Read  
**Description**: Gets the details of the points contract.  
**Input Parameters**: None  
**Output**:
- `(ByteArray, ByteArray, ByteArray, u8, u256)`: Tuple containing:
  - Name of the points contract
  - Symbol of the points contract
  - Metadata of the points contract
  - Decimals of the points contract
  - Total supply of the points contract

#### upgrade
**Type**: Write  
**Description**: Upgrades the contract to a new implementation.  
**Input Parameters**:
- `new_class_hash` (ClassHash): The class hash of the new implementation

**Output**: None  
**Access Control**: Only owner  

## InfiniRewardsCollectible

The InfiniRewardsCollectible contract is an ERC1155-compatible token used for collectibles.

### Methods

#### pause
**Type**: Write  
**Description**: Pauses the contract, preventing certain operations.  
**Input Parameters**: None  
**Output**: None  
**Access Control**: Only owner  

#### unpause
**Type**: Write  
**Description**: Unpauses the contract, allowing operations to resume.  
**Input Parameters**: None  
**Output**: None  
**Access Control**: Only owner  

#### burn
**Type**: Write  
**Description**: Burns (destroys) a specified amount of collectibles from an account.  
**Input Parameters**:
- `account` (ContractAddress): The account to burn collectibles from
- `token_id` (u256): The ID of the collectible to burn
- `value` (u256): The amount of collectibles to burn

**Output**: None  
**Access Control**: Caller must be the account or approved for all  

#### batch_burn
**Type**: Write  
**Description**: Burns multiple collectibles from an account in a single transaction.  
**Input Parameters**:
- `account` (ContractAddress): The account to burn collectibles from
- `token_ids` (Span<u256>): The IDs of the collectibles to burn
- `values` (Span<u256>): The amounts of each collectible to burn

**Output**: None  
**Access Control**: Caller must be the account or approved for all  

#### mint
**Type**: Write  
**Description**: Mints (creates) a specified amount of collectibles to an account.  
**Input Parameters**:
- `account` (ContractAddress): The account to receive the collectibles
- `token_id` (u256): The ID of the collectible to mint
- `value` (u256): The amount of collectibles to mint
- `data` (Span<felt252>): Additional data for the minting operation

**Output**: None  
**Access Control**: Only owner  

#### batch_mint
**Type**: Write  
**Description**: Mints multiple collectibles to an account in a single transaction.  
**Input Parameters**:
- `account` (ContractAddress): The account to receive the collectibles
- `token_ids` (Span<u256>): The IDs of the collectibles to mint
- `values` (Span<u256>): The amounts of each collectible to mint
- `data` (Span<felt252>): Additional data for the minting operation

**Output**: None  
**Access Control**: Only owner  

#### set_base_uri
**Type**: Write  
**Description**: Sets the base URI for token metadata.  
**Input Parameters**:
- `base_uri` (ByteArray): The new base URI

**Output**: None  
**Access Control**: Only owner  

#### set_token_data
**Type**: Write  
**Description**: Sets the data for a specific token ID.  
**Input Parameters**:
- `token_id` (u256): The ID of the token to set data for
- `points_contract` (ContractAddress): The points contract associated with this collectible
- `price` (u256): The price of the collectible in points
- `expiry` (u64): The expiry timestamp for the collectible
- `metadata` (ByteArray): Additional metadata for the collectible

**Output**: None  
**Access Control**: Only owner  

#### get_token_data
**Type**: Read  
**Description**: Gets the data for a specific token ID.  
**Input Parameters**:
- `token_id` (u256): The ID of the token to get data for

**Output**:
- `(ContractAddress, u256, u64, ByteArray, u256)`: Tuple containing:
  - Points contract address
  - Price in points
  - Expiry timestamp
  - Metadata
  - Current supply

#### redeem
**Type**: Write  
**Description**: Redeems a collectible, burning it in the process.  
**Input Parameters**:
- `user` (ContractAddress): The user redeeming the collectible
- `token_id` (u256): The ID of the collectible to redeem
- `amount` (u256): The amount of collectibles to redeem

**Output**: None  

#### purchase
**Type**: Write  
**Description**: Purchases a collectible using points.  
**Input Parameters**:
- `user` (ContractAddress): The user purchasing the collectible
- `token_id` (u256): The ID of the collectible to purchase
- `amount` (u256): The amount of collectibles to purchase

**Output**: None  

#### get_details
**Type**: Read  
**Description**: Gets the details of the collectible contract.  
**Input Parameters**: None  
**Output**:
- `(ByteArray, ByteArray, ContractAddress, Array<u256>, Array<u256>, Array<u64>, Array<ByteArray>, Array<u256>)`: Tuple containing:
  - Name of the collectible contract
  - Metadata of the collectible contract
  - Points contract address
  - Array of token IDs
  - Array of token prices
  - Array of token expiry timestamps
  - Array of token metadata
  - Array of token supplies

#### is_valid
**Type**: Read  
**Description**: Checks if a collectible is still valid (not expired).  
**Input Parameters**:
- `token_id` (u256): The ID of the collectible to check

**Output**:
- `bool`: True if the collectible is valid, false otherwise

#### set_points_contract
**Type**: Write  
**Description**: Sets the points contract for the collectible contract.  
**Input Parameters**:
- `points_contract` (ContractAddress): The new points contract address

**Output**: None  
**Access Control**: Only owner  

#### set_details
**Type**: Write  
**Description**: Sets the details of the collectible contract.  
**Input Parameters**:
- `name` (ByteArray): The new name for the collectible contract
- `metadata` (ByteArray): The new metadata for the collectible contract

**Output**: None  
**Access Control**: Only owner  

#### upgrade
**Type**: Write  
**Description**: Upgrades the contract to a new implementation.  
**Input Parameters**:
- `new_class_hash` (ClassHash): The class hash of the new implementation

**Output**: None  
**Access Control**: Only owner  

## InfiniRewardsUserAccount

The InfiniRewardsUserAccount contract represents a user account in the InfiniRewards system.

### Methods

#### set_metadata
**Type**: Write  
**Description**: Sets the metadata for the user account.  
**Input Parameters**:
- `metadata` (ByteArray): The new metadata

**Output**: None  

#### get_metadata
**Type**: Read  
**Description**: Gets the metadata for the user account.  
**Input Parameters**: None  
**Output**:
- `ByteArray`: The metadata of the user account

#### upgrade
**Type**: Write  
**Description**: Upgrades the contract to a new implementation.  
**Input Parameters**:
- `new_class_hash` (ClassHash): The class hash of the new implementation

**Output**: None  
**Access Control**: Only self  

## InfiniRewardsMerchantAccount

The InfiniRewardsMerchantAccount contract represents a merchant account in the InfiniRewards system.

### Methods

#### add_points_contract
**Type**: Write  
**Description**: Adds a points contract to the merchant account.  
**Input Parameters**:
- `points_contract` (ContractAddress): The address of the points contract to add

**Output**: None  

#### add_collectible_contract
**Type**: Write  
**Description**: Adds a collectible contract to the merchant account.  
**Input Parameters**:
- `collectible_contract` (ContractAddress): The address of the collectible contract to add

**Output**: None  

#### set_metadata
**Type**: Write  
**Description**: Sets the metadata for the merchant account.  
**Input Parameters**:
- `metadata` (ByteArray): The new metadata

**Output**: None  

#### get_points_contracts
**Type**: Read  
**Description**: Gets all points contracts associated with the merchant account.  
**Input Parameters**: None  
**Output**:
- `Array<ContractAddress>`: Array of points contract addresses

#### get_collectible_contracts
**Type**: Read  
**Description**: Gets all collectible contracts associated with the merchant account.  
**Input Parameters**: None  
**Output**:
- `Array<ContractAddress>`: Array of collectible contract addresses

#### get_metadata
**Type**: Read  
**Description**: Gets the metadata for the merchant account.  
**Input Parameters**: None  
**Output**:
- `ByteArray`: The metadata of the merchant account

#### upgrade
**Type**: Write  
**Description**: Upgrades the contract to a new implementation.  
**Input Parameters**:
- `new_class_hash` (ClassHash): The class hash of the new implementation

**Output**: None  
**Access Control**: Only self  