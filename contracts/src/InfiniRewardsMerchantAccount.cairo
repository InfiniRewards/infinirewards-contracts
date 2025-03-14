// SPDX-License-Identifier: MIT

#[starknet::contract(account)]
mod InfiniRewardsMerchantAccount {
    use contracts::components::account::AccountComponent;
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::upgrades::UpgradeableComponent;
    use openzeppelin::upgrades::interface::IUpgradeable;
    use starknet::{ClassHash, ContractAddress};
    use starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess, Vec, VecTrait, MutableVecTrait
    };
    use contracts::interfaces::IInfiniRewardsMerchantAccount::IInfiniRewardsMerchantAccount;

    component!(path: AccountComponent, storage: account, event: AccountEvent);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);

    #[abi(embed_v0)]
    impl SRC6Impl = AccountComponent::SRC6Impl<ContractState>;
    #[abi(embed_v0)]
    impl SRC6CamelOnlyImpl = AccountComponent::SRC6CamelOnlyImpl<ContractState>;
    #[abi(embed_v0)]
    impl DeclarerImpl = AccountComponent::DeclarerImpl<ContractState>;
    #[abi(embed_v0)]
    impl DeployableImpl = AccountComponent::DeployableImpl<ContractState>;
    #[abi(embed_v0)]
    impl PublicKeyImpl = AccountComponent::PublicKeyImpl<ContractState>;
    #[abi(embed_v0)]
    impl PublicKeyCamelImpl = AccountComponent::PublicKeyCamelImpl<ContractState>;
    #[abi(embed_v0)]
    impl SRC5Impl = SRC5Component::SRC5Impl<ContractState>;

    impl AccountInternalImpl = AccountComponent::InternalImpl<ContractState>;
    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        account: AccountComponent::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
        metadata: ByteArray,
        points_contracts: Vec<ContractAddress>,
        collectible_contracts: Vec<ContractAddress>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        AccountEvent: AccountComponent::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
    }

    #[constructor]
    fn constructor(ref self: ContractState, public_key: felt252) {
        self.account.initializer(public_key);
    }

    #[abi(embed_v0)]
    impl UpgradeableImpl of IUpgradeable<ContractState> {
        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            self.account.assert_only_self();
            self.upgradeable.upgrade(new_class_hash);
        }
    }

    #[abi(embed_v0)]
    impl IInfiniRewardsMerchantAccountImpl of IInfiniRewardsMerchantAccount<ContractState> {
        fn add_points_contract(ref self: ContractState, points_contract: ContractAddress) {
            self.points_contracts.push(points_contract);
        }

        fn add_collectible_contract(
            ref self: ContractState, collectible_contract: ContractAddress
        ) {
            self.collectible_contracts.push(collectible_contract);
        }

        fn set_metadata(ref self: ContractState, metadata: ByteArray) {
            self.metadata.write(metadata);
        }
    }

    #[generate_trait]
    #[abi(per_item)]
    impl ExternalImpl of ExternalTrait {
        #[external(v0)]
        fn get_points_contracts(self: @ContractState) -> Array::<ContractAddress> {
            let mut addresses = array![];
            for i in 0
                ..self
                    .points_contracts
                    .len() {
                        addresses.append(self.points_contracts.at(i).read());
                    };
            addresses
        }

        #[external(v0)]
        fn get_collectible_contracts(self: @ContractState) -> Array::<ContractAddress> {
            let mut addresses = array![];
            for i in 0
                ..self
                    .collectible_contracts
                    .len() {
                        addresses.append(self.collectible_contracts.at(i).read());
                    };
            addresses
        }

        #[external(v0)]
        fn get_metadata(self: @ContractState) -> ByteArray {
            self.metadata.read()
        }
    }
}
