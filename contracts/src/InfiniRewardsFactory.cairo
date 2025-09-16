// SPDX-License-Identifier: MIT

#[starknet::contract]
mod InfiniRewardsFactory {
    use openzeppelin_access::ownable::OwnableComponent;
    use openzeppelin_security::pausable::PausableComponent;
    use openzeppelin_upgrades::UpgradeableComponent;
    use openzeppelin_interfaces::upgrades::IUpgradeable;
    use starknet::{ClassHash, ContractAddress, get_caller_address};
    use starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess
    };
    use starknet::syscalls::deploy_syscall;
    use contracts::interfaces::IInfiniRewardsMerchantAccount::{IInfiniRewardsMerchantAccountDispatcherTrait, IInfiniRewardsMerchantAccountDispatcher};
    use contracts::interfaces::IInfiniRewardsUserAccount::{IInfiniRewardsUserAccountDispatcherTrait, IInfiniRewardsUserAccountDispatcher};

    component!(path: PausableComponent, storage: pausable, event: PausableEvent);
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);

    #[abi(embed_v0)]
    impl PausableImpl = PausableComponent::PausableImpl<ContractState>;
    #[abi(embed_v0)]
    impl OwnableMixinImpl = OwnableComponent::OwnableMixinImpl<ContractState>;

    impl PausableInternalImpl = PausableComponent::InternalImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;
    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        pausable: PausableComponent::Storage,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
        infini_rewards_points_hash: ClassHash,
        infini_rewards_collectible_hash: ClassHash,
        infini_rewards_certificate_hash: ClassHash,
        infini_rewards_user_account_hash: ClassHash,
        infini_rewards_merchant_account_hash: ClassHash,
        // user_accounts: Map::<felt252, ContractAddress>,
        // merchant_accounts: Map::<felt252, ContractAddress>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        PausableEvent: PausableComponent::Event,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
        UserCreated: UserCreated,
        MerchantCreated: MerchantCreated,
        PointsCreated: PointsCreated,
        CollectibleCreated: CollectibleCreated,
        CertificateCreated: CertificateCreated,
    }

    #[derive(Drop, starknet::Event)]
    struct UserCreated {
        user: ContractAddress,
        metadata: ByteArray,
    }

    #[derive(Drop, starknet::Event)]
    struct MerchantCreated {
        merchant: ContractAddress,
        points_contract: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    struct PointsCreated {
        points_contract: ContractAddress,
        merchant: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    struct CollectibleCreated {
        collectible_contract: ContractAddress,
        merchant: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    struct CertificateCreated {
        certificate_contract: ContractAddress,
        merchant: ContractAddress,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        infini_rewards_points_hash: ClassHash,
        infini_rewards_collectible_hash: ClassHash,
        infini_rewards_certificate_hash: ClassHash,
        infini_rewards_user_account_hash: ClassHash,
        infini_rewards_merchant_account_hash: ClassHash,
        owner: ContractAddress
    ) {
        self.infini_rewards_points_hash.write(infini_rewards_points_hash);
        self.infini_rewards_collectible_hash.write(infini_rewards_collectible_hash);
        self.infini_rewards_certificate_hash.write(infini_rewards_certificate_hash);
        self.infini_rewards_user_account_hash.write(infini_rewards_user_account_hash);
        self.infini_rewards_merchant_account_hash.write(infini_rewards_merchant_account_hash);
        self.ownable.initializer(owner);
    }

    #[abi(embed_v0)]
    impl UpgradeableImpl of IUpgradeable<ContractState> {
        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            self.ownable.assert_only_owner();
            self.upgradeable.upgrade(new_class_hash);
        }
    }

    #[generate_trait]
    #[abi(per_item)]
    impl ExternalImpl of ExternalTrait {
        #[external(v0)]
        fn pause(ref self: ContractState) {
            self.ownable.assert_only_owner();
            self.pausable.pause();
        }

        #[external(v0)]
        fn unpause(ref self: ContractState) {
            self.ownable.assert_only_owner();
            self.pausable.unpause();
        }

        #[external(v0)]
        fn create_user(
            ref self: ContractState,
            public_key: felt252,
            metadata: ByteArray
        ) -> ContractAddress {
            // assert(self.user_accounts.read(phone_number_hash).is_zero(), 'User already exists');
            
            let mut constructor_calldata = ArrayTrait::new();
            public_key.serialize(ref constructor_calldata);
            let (new_account, _) = deploy_syscall(
                    self.infini_rewards_user_account_hash.read(), public_key, constructor_calldata.span(), true
                )
                    .expect('failed to deploy account');
            // self.user_accounts.write(phone_number_hash, new_account);
            let user_account_instance = IInfiniRewardsUserAccountDispatcher { contract_address: new_account };
            user_account_instance.set_metadata(metadata.clone());
            self.emit(UserCreated { user: new_account, metadata });
            new_account
        }

        #[external(v0)]
        fn create_merchant_contract(
            ref self: ContractState,
            public_key: felt252,
            metadata: ByteArray,
            name: ByteArray,
            symbol: ByteArray,
            decimals: u8
        ) -> (ContractAddress, ContractAddress) {
            // Create user account first
            // assert(self.merchant_accounts.read(phone_number_hash).is_zero(), 'Merchant already exists');
            
            let mut constructor_calldata = ArrayTrait::new();
            public_key.serialize(ref constructor_calldata);
            let (merchant, _) = deploy_syscall(
                    self.infini_rewards_merchant_account_hash.read(), public_key, constructor_calldata.span(), true
                )
                    .expect('failed to deploy account');

            // Deploy Points Contract within Merchant Account
            let mut points_calldata = ArrayTrait::new();
            merchant.serialize(ref points_calldata);
            name.serialize(ref points_calldata);
            symbol.serialize(ref points_calldata);
            let mut points_metadata = Default::default();
            points_metadata.append_word(0xb900016b6465736372697074696f6e6e44656661756c7420506f696e7473, 30); // Default Points Metadata: {"description":"Default Points"}
            points_metadata.serialize(ref points_calldata);
            decimals.serialize(ref points_calldata);
            let (points_contract, _) = deploy_syscall(
                    self.infini_rewards_points_hash.read(), 
                    0, 
                    points_calldata.span(), 
                    false
                )
                    .expect('failed to deploy points');
            // Initialize merchant account with points contract
            let merchant_account_instance = IInfiniRewardsMerchantAccountDispatcher { contract_address: merchant };
            merchant_account_instance.add_points_contract(points_contract);
            merchant_account_instance.set_metadata(metadata.clone());

            self.emit(MerchantCreated { merchant, points_contract });
            (merchant, points_contract)
        }

        #[external(v0)]
        fn create_points_contract(
            ref self: ContractState,
            name: ByteArray,
            symbol: ByteArray,
            metadata: ByteArray,
            decimals: u8
        ) -> ContractAddress {           
            let mut constructor_calldata = ArrayTrait::new();
            let merchant: ContractAddress = get_caller_address();
            merchant.serialize(ref constructor_calldata);
            name.serialize(ref constructor_calldata);
            symbol.serialize(ref constructor_calldata);
            metadata.serialize(ref constructor_calldata);
            decimals.serialize(ref constructor_calldata);
            let (new_contract, _) = deploy_syscall(
                    self.infini_rewards_points_hash.read(), 0, constructor_calldata.span(), false
                )
                    .expect('failed to deploy points');
            let merchant_account_instance = IInfiniRewardsMerchantAccountDispatcher { contract_address: merchant };
            merchant_account_instance.add_points_contract(new_contract);
            self.emit(PointsCreated { points_contract: new_contract, merchant });
            new_contract
        }

        #[external(v0)]
        fn create_collectible_contract(
            ref self: ContractState,
            name: ByteArray,
            metadata: ByteArray,
        ) -> ContractAddress {
            let mut constructor_calldata = ArrayTrait::new();
            let merchant = get_caller_address();
            merchant.serialize(ref constructor_calldata);
            name.serialize(ref constructor_calldata);
            metadata.serialize(ref constructor_calldata);

            let (new_contract, _) = deploy_syscall(
                self.infini_rewards_collectible_hash.read(),
                0,
                constructor_calldata.span(),
                false
            ).expect('deploy failed');

            let merchant_account_instance = IInfiniRewardsMerchantAccountDispatcher { contract_address: merchant };
            merchant_account_instance.add_collectible_contract(new_contract);
            self.emit(CollectibleCreated { collectible_contract: new_contract, merchant });
            new_contract
        }

        #[external(v0)]
        fn create_certificate_contract(
            ref self: ContractState,
            name: ByteArray,
            metadata: ByteArray,
        ) -> ContractAddress {
            let mut constructor_calldata = ArrayTrait::new();
            let merchant = get_caller_address();
            merchant.serialize(ref constructor_calldata);
            name.serialize(ref constructor_calldata);
            metadata.serialize(ref constructor_calldata);

            let (new_contract, _) = deploy_syscall(
                self.infini_rewards_certificate_hash.read(),
                0,
                constructor_calldata.span(),
                false
            ).expect('deploy failed');

            let merchant_account_instance = IInfiniRewardsMerchantAccountDispatcher { contract_address: merchant };
            merchant_account_instance.add_certificate_contract(new_contract);
            self.emit(CertificateCreated { certificate_contract: new_contract, merchant });
            new_contract
        }

        #[external(v0)]
        fn get_user_class_hash(self: @ContractState) -> ClassHash {
            self.infini_rewards_user_account_hash.read()
        }

        #[external(v0)]
        fn set_user_class_hash(ref self: ContractState, class_hash: ClassHash) {
            self.ownable.assert_only_owner();
            self.infini_rewards_user_account_hash.write(class_hash);
        }

        #[external(v0)]
        fn get_merchant_class_hash(self: @ContractState) -> ClassHash {
            self.infini_rewards_merchant_account_hash.read()
        }

        #[external(v0)]
        fn set_merchant_class_hash(ref self: ContractState, class_hash: ClassHash) {
            self.ownable.assert_only_owner();
            self.infini_rewards_merchant_account_hash.write(class_hash);
        }

        #[external(v0)]
        fn get_points_class_hash(self: @ContractState) -> ClassHash {
            self.infini_rewards_points_hash.read()
        }

        #[external(v0)]
        fn set_points_class_hash(ref self: ContractState, class_hash: ClassHash) {
            self.ownable.assert_only_owner();
            self.infini_rewards_points_hash.write(class_hash);
        }

        #[external(v0)]
        fn get_collectible_class_hash(self: @ContractState) -> ClassHash {
            self.infini_rewards_collectible_hash.read()
        }

        #[external(v0)]
        fn set_collectible_class_hash(ref self: ContractState, class_hash: ClassHash) {
            self.ownable.assert_only_owner();
            self.infini_rewards_collectible_hash.write(class_hash);
        }

        #[external(v0)]
        fn get_certificate_class_hash(self: @ContractState) -> ClassHash {
            self.infini_rewards_certificate_hash.read()
        }

        #[external(v0)]
        fn set_certificate_class_hash(ref self: ContractState, class_hash: ClassHash) {
            self.ownable.assert_only_owner();
            self.infini_rewards_certificate_hash.write(class_hash);
        }
    }
}
