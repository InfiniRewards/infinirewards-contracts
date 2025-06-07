use starknet::ContractAddress;

#[starknet::interface]
pub trait IInfiniRewardsPoints<TContractState> {
    fn burn(ref self: TContractState, account: ContractAddress, amount: u256) -> bool;
    fn mint(ref self: TContractState, account: ContractAddress, amount: u256) -> bool;
}
