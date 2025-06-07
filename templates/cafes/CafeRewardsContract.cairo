// SPDX-License-Identifier: MIT

#[starknet::contract]
mod CafeRewardsContract {
    use starknet::ContractAddress;
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess, Map};
    use contracts::interfaces::IInfiniRewardsPoints::IInfiniRewardsPointsDispatcher;
    use contracts::interfaces::IInfiniRewardsPoints::IInfiniRewardsPointsDispatcherTrait;

    #[storage]
    struct Storage {
        stamps_required: u8,
        stamps: Map::<ContractAddress, u8>,
        points_contract: ContractAddress,
    }

    #[event]
    fn StampIssued(customer: ContractAddress, total: u8);

    #[event]
    fn FreeDrinkRedeemed(customer: ContractAddress);

    #[constructor]
    fn constructor(ref self: ContractState, stamps_required: u8, points_contract: ContractAddress) {
        self.stamps_required.write(stamps_required);
        self.points_contract.write(points_contract);
    }

    #[external]
    fn issue_stamp(ref self: ContractState, customer: ContractAddress) {
        let current = self.stamps.entry(customer).read();
        let updated = current + 1_u8;
        self.stamps.entry(customer).write(updated);
        StampIssued(customer, updated);
    }

    #[external]
    fn redeem_free_drink(ref self: ContractState, customer: ContractAddress) {
        let count = self.stamps.entry(customer).read();
        let required = self.stamps_required.read();
        assert(count >= required, 'Not enough stamps');
        self.stamps.entry(customer).write(0_u8);
        let points_contract = self.points_contract.read();
        let points_contract_dispatcher = IInfiniRewardsPointsDispatcher { contract_address: points_contract };
        let _ = points_contract_dispatcher.mint(customer, required.into());
        FreeDrinkRedeemed(customer);
    }
}
