// SPDX-License-Identifier: MIT

/// @title IInfiniRewardsMerchantAccount Interface
/// @notice Interface for interacting with InfiniRewardsMerchantAccount contract

#[starknet::interface]
pub trait IInfiniRewardsUserAccount<TContractState> {
    /// @notice Sets the metadata for the user account
    /// @param metadata The metadata to set
    fn set_metadata(ref self: TContractState, metadata: ByteArray);

}