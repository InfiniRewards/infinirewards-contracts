// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts for Cairo ^0.16.0

#[starknet::contract]
mod InfiniRewardsPoints {
    use openzeppelin_access::ownable::OwnableComponent;
    use openzeppelin_security::pausable::PausableComponent;
    use openzeppelin_token::erc20::ERC20Component;
    use openzeppelin_upgrades::UpgradeableComponent;
    use openzeppelin_interfaces::upgrades::IUpgradeable;
    use starknet::ClassHash;
    use starknet::ContractAddress;
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};
    use starknet::get_caller_address;

    component!(path: ERC20Component, storage: erc20, event: ERC20Event);
    component!(path: PausableComponent, storage: pausable, event: PausableEvent);
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);

    // ERC20 Configuration
    impl ERC20ImmutableConfig of ERC20Component::ImmutableConfig {
        const DECIMALS: u8 = 18;
    }

    #[abi(embed_v0)]
    impl ERC20MixinImpl = ERC20Component::ERC20MixinImpl<ContractState>;
    #[abi(embed_v0)]
    impl PausableImpl = PausableComponent::PausableImpl<ContractState>;
    #[abi(embed_v0)]
    impl OwnableMixinImpl = OwnableComponent::OwnableMixinImpl<ContractState>;

    impl ERC20InternalImpl = ERC20Component::InternalImpl<ContractState>;
    impl PausableInternalImpl = PausableComponent::InternalImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;
    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc20: ERC20Component::Storage,
        #[substorage(v0)]
        pausable: PausableComponent::Storage,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
        name: ByteArray,
        symbol: ByteArray,
        metadata: ByteArray,
        decimals: u8,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC20Event: ERC20Component::Event,
        #[flat]
        PausableEvent: PausableComponent::Event,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        owner: ContractAddress,
        name: ByteArray,
        symbol: ByteArray,
        metadata: ByteArray,
        decimals: u8
    ) {
        let name_clone = name.clone();
        let symbol_clone = symbol.clone();
        self.erc20.initializer(name_clone, symbol_clone);
        self.ownable.initializer(owner);
        self.name.write(name);
        self.symbol.write(symbol);
        self.metadata.write(metadata);
        self.decimals.write(decimals);
    }

    impl ERC20HooksImpl of ERC20Component::ERC20HooksTrait<ContractState> {
        fn before_update(
            ref self: ERC20Component::ComponentState<ContractState>,
            from: ContractAddress,
            recipient: ContractAddress,
            amount: u256,
        ) {
            let contract_state = ERC20Component::HasComponent::get_contract(@self);
            contract_state.pausable.assert_not_paused();
        }

        fn after_update(
            ref self: ERC20Component::ComponentState<ContractState>,
            from: ContractAddress,
            recipient: ContractAddress,
            amount: u256,
        ) {
        }
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
        fn burn(ref self: ContractState, value: u256) {
            self.erc20.burn(get_caller_address(), value);
        }

        #[external(v0)]
        fn mint(ref self: ContractState, recipient: ContractAddress, amount: u256) {
            self.ownable.assert_only_owner();
            self.erc20.mint(recipient, amount);
        }

        #[external(v0)]
        fn update_metadata(ref self: ContractState, metadata: ByteArray) {
            self.ownable.assert_only_owner();
            self.metadata.write(metadata);
        }

        #[external(v0)]
        fn get_details(self: @ContractState) -> (ByteArray, ByteArray, ByteArray, u8, u256) {
            (self.name.read(), self.symbol.read(), self.metadata.read(), self.decimals.read(), self.erc20.ERC20_total_supply.read())
        }
    }
}
