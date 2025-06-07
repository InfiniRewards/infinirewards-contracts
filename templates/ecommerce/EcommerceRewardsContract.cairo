// SPDX-License-Identifier: MIT

#[starknet::contract]
mod EcommerceRewardsContract {
    use starknet::ContractAddress;
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess, Map};
    use contracts::interfaces::IInfiniRewardsPoints::IInfiniRewardsPointsDispatcher;
    use contracts::interfaces::IInfiniRewardsPoints::IInfiniRewardsPointsDispatcherTrait;
    use contracts::interfaces::IInfiniRewardsCollectible::IInfiniRewardsCollectibleDispatcher;
    use contracts::interfaces::IInfiniRewardsCollectible::IInfiniRewardsCollectibleDispatcherTrait;
    use core::integer::u256;
    use array::ArrayTrait;

    #[storage]
    struct Storage {
        cashback_rate: u8,
        points_contract: ContractAddress,
        voucher_collectible: ContractAddress,
    }

    #[constructor]
    fn constructor(ref self: ContractState, cashback_rate: u8, points_contract: ContractAddress, voucher_collectible: ContractAddress) {
        self.cashback_rate.write(cashback_rate);
        self.points_contract.write(points_contract);
        self.voucher_collectible.write(voucher_collectible);
    }

    #[external]
    fn record_purchase(ref self: ContractState, buyer: ContractAddress, amount: u256) {
        let points_contract = self.points_contract.read();
        let dispatcher = IInfiniRewardsPointsDispatcher { contract_address: points_contract };
        let _ = dispatcher.mint(buyer, amount);
    }

    #[external]
    fn issue_voucher(ref self: ContractState, buyer: ContractAddress, token_id: u256) {
        let coll = self.voucher_collectible.read();
        let dispatcher = IInfiniRewardsCollectibleDispatcher { contract_address: coll };
        let empty = ArrayTrait::new();
        dispatcher.mint(buyer, token_id, 1_u256, empty.span());
    }

}
