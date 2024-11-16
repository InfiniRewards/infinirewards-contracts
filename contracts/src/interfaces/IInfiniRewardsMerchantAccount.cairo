// SPDX-License-Identifier: MIT

use starknet::ContractAddress;

/// @title IInfiniRewardsMerchantAccount Interface
/// @notice Interface for interacting with InfiniRewardsMerchantAccount contract

#[starknet::interface]
pub trait IInfiniRewardsMerchantAccount<TContractState> {
    /// @notice Adds a points contract to the merchant account
    /// @param points_contract The address of the points contract to add
    fn add_points_contract(ref self: TContractState, points_contract: ContractAddress);

    /// @notice Adds a collectible contract to the merchant account
    /// @param collectible_contract The address of the collectible contract to add
    fn add_collectible_contract(ref self: TContractState, collectible_contract: ContractAddress);
}