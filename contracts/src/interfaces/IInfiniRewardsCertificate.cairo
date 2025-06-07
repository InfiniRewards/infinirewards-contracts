use starknet::{ContractAddress, Span, felt252};

#[starknet::interface]
pub trait IInfiniRewardsCertificate<TContractState> {
    fn mint(
        ref self: TContractState,
        account: ContractAddress,
        token_id: u256,
        value: u256,
        data: Span<felt252>,
    ) -> bool;
}
