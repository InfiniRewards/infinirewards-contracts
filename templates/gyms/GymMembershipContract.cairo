// SPDX-License-Identifier: MIT

#[starknet::contract]
mod GymMembershipContract {
    use starknet::ContractAddress;
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess, Map};
    use starknet::syscalls::get_block_timestamp_syscall;
    use array::ArrayTrait;
    use contracts::interfaces::IInfiniRewardsCollectible::IInfiniRewardsCollectibleDispatcher;
    use contracts::interfaces::IInfiniRewardsCollectible::IInfiniRewardsCollectibleDispatcherTrait;

    #[storage]
    struct Storage {
        membership_duration: u64,
        expiry: Map::<ContractAddress, u64>,
        collectible_contract: ContractAddress,
    }

    #[constructor]
    fn constructor(ref self: ContractState, membership_duration: u64, collectible_contract: ContractAddress) {
        self.membership_duration.write(membership_duration);
        self.collectible_contract.write(collectible_contract);
    }

    #[external]
    fn register_member(ref self: ContractState, member: ContractAddress) {
        let now = get_block_timestamp_syscall().timestamp;
        let duration = self.membership_duration.read();
        self.expiry.entry(member).write(now + duration);
        let coll_contract = self.collectible_contract.read();
        let coll_dispatcher = IInfiniRewardsCollectibleDispatcher { contract_address: coll_contract };
        let empty = ArrayTrait::new();
        coll_dispatcher.mint(member, 1_u256, 1_u256, empty.span());
    }

    #[view]
    fn is_active(self: @ContractState, member: ContractAddress) -> bool {
        let expires = self.expiry.entry(member).read();
        let now = get_block_timestamp_syscall().timestamp;
        return now < expires;
    }
}
