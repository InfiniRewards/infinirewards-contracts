// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts for Cairo ^0.16.0

#[starknet::contract]
mod InfiniRewardsCertificate {
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::security::pausable::PausableComponent;
    use openzeppelin::token::erc1155::ERC1155Component;
    use openzeppelin::upgrades::UpgradeableComponent;
    use openzeppelin::upgrades::interface::IUpgradeable;
    use starknet::ClassHash;
    use starknet::{ContractAddress, get_caller_address};
    use starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess, Map, StoragePathEntry, Vec, VecTrait, MutableVecTrait
    };
    use core::assert;
    use core::num::traits::Zero;
    use starknet::syscalls::get_execution_info_syscall;
    use contracts::interfaces::IInfiniRewards::Errors;

    component!(path: ERC1155Component, storage: erc1155, event: ERC1155Event);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: PausableComponent, storage: pausable, event: PausableEvent);
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);

    #[abi(embed_v0)]
    impl ERC1155MixinImpl = ERC1155Component::ERC1155MixinImpl<ContractState>;
    #[abi(embed_v0)]
    impl PausableImpl = PausableComponent::PausableImpl<ContractState>;
    #[abi(embed_v0)]
    impl OwnableMixinImpl = OwnableComponent::OwnableMixinImpl<ContractState>;

    impl ERC1155InternalImpl = ERC1155Component::InternalImpl<ContractState>;
    impl PausableInternalImpl = PausableComponent::InternalImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;
    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc1155: ERC1155Component::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        pausable: PausableComponent::Storage,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
        name: ByteArray,
        metadata: ByteArray,
        token_ids: Vec::<u256>,
        token_expiries: Map::<u256, u64>,
        token_metadatas: Map::<u256, ByteArray>,
        token_supplies: Map::<u256, u256>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC1155Event: ERC1155Component::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
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
        metadata: ByteArray
    ) {
        self.name.write(name);
        self.erc1155.initializer(self.name.read());
        self.ownable.initializer(owner);
        self.metadata.write(metadata);
    }

    impl ERC1155HooksImpl of ERC1155Component::ERC1155HooksTrait<ContractState> {
        fn before_update(
            ref self: ERC1155Component::ComponentState<ContractState>,
            from: ContractAddress,
            to: ContractAddress,
            token_ids: Span<u256>,
            values: Span<u256>,
        ) {
            let contract_state = ERC1155Component::HasComponent::get_contract(@self);
            contract_state.pausable.assert_not_paused();
            if !from.is_zero() && !to.is_zero() {
                assert(false, Errors::NON_TRANSFERABLE);
            }
        }

        fn after_update(
            ref self: ERC1155Component::ComponentState<ContractState>,
            from: ContractAddress,
            to: ContractAddress,
            token_ids: Span<u256>,
            values: Span<u256>,
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
        fn burn(ref self: ContractState, account: ContractAddress, token_id: u256, value: u256) {
            let caller = get_caller_address();
            if account != caller {
                assert(self.erc1155.is_approved_for_all(account, caller), ERC1155Component::Errors::UNAUTHORIZED);
            }
            self.erc1155.burn(account, token_id, value);
            let supply = self.token_supplies.entry(token_id).read();
            self.token_supplies.entry(token_id).write(supply - value);
        }

        #[external(v0)]
        fn batch_burn(
            ref self: ContractState,
            account: ContractAddress,
            token_ids: Span<u256>,
            values: Span<u256>,
        ) {
            let caller = get_caller_address();
            if account != caller {
                assert(self.erc1155.is_approved_for_all(account, caller), ERC1155Component::Errors::UNAUTHORIZED);
            }
            self.erc1155.batch_burn(account, token_ids, values);
            for i in 0..token_ids.len() {
                let token_id = *token_ids.at(i);
                let supply = self.token_supplies.entry(token_id).read();
                self.token_supplies.entry(token_id).write(supply - *values.at(i));
            };
        }

        #[external(v0)]
        fn mint(
            ref self: ContractState,
            account: ContractAddress,
            token_id: u256,
            value: u256,
            data: Span<felt252>,
        ) {
            self.ownable.assert_only_owner();
            let mut token_exists:bool = false;
            for i in 0..self.token_ids.len() {
                let curr_token_id:u256 = self.token_ids.at(i).read();
                if curr_token_id == token_id {
                    token_exists = true;
                    break;
                }
            };
            assert(token_exists, Errors::CERTIFICATE_NOT_EXIST);
            let supply = self.token_supplies.entry(token_id).read();
            self.token_supplies.entry(token_id).write(supply + value);
            self.erc1155.mint_with_acceptance_check(account, token_id, value, data);
        }

        #[external(v0)]
        fn batch_mint(
            ref self: ContractState,
            account: ContractAddress,
            token_ids: Span<u256>,
            values: Span<u256>,
            data: Span<felt252>,
        ) {
            self.ownable.assert_only_owner();
            for i in 0..token_ids.len() {
                let token_id = *token_ids.at(i);
                let supply = self.token_supplies.entry(token_id).read();
                self.token_supplies.entry(token_id).write(supply + *values.at(i));
            };
            self.erc1155.batch_mint_with_acceptance_check(account, token_ids, values, data);
        }

        #[external(v0)]
        fn set_token_data(ref self: ContractState, token_id: u256, expiry: u64, metadata: ByteArray) {
            self.ownable.assert_only_owner();
            let mut token_exists:bool = false;
            for i in 0..self.token_ids.len() {
                let curr_token_id:u256 = self.token_ids.at(i).read();
                if curr_token_id == token_id {
                    token_exists = true;
                    break;
                }
            };
            if !token_exists {
                self.token_ids.push(token_id);
            }
            self.token_expiries.entry(token_id).write(expiry);
            self.token_metadatas.entry(token_id).write(metadata);
        }

        #[external(v0)]
        fn get_token_data(self: @ContractState, token_id: u256) -> (u64, ByteArray, u256) {
            (self.token_expiries.entry(token_id).read(), self.token_metadatas.entry(token_id).read(), self.token_supplies.entry(token_id).read())
        }

        #[external(v0)]
        fn get_details(self: @ContractState) -> (ByteArray, ByteArray, Array::<u256>, Array::<u64>, Array::<ByteArray>, Array::<u256>) {
            let mut token_ids: Array::<u256> = array![];
            let mut token_expiries: Array::<u64> = array![];
            let mut token_metadatas: Array::<ByteArray> = array![];
            let mut token_supplies: Array::<u256> = array![];
            for i in 0..self.token_ids.len() {
                let token_id = self.token_ids.at(i).read();
                token_ids.append(token_id);
                token_expiries.append(self.token_expiries.entry(token_id).read());
                token_metadatas.append(self.token_metadatas.entry(token_id).read());
                token_supplies.append(self.token_supplies.entry(token_id).read());
            };
            (
                self.name.read(),
                self.metadata.read(),
                token_ids,
                token_expiries,
                token_metadatas,
                token_supplies
            )
        }

        #[external(v0)]
        fn is_valid(self: @ContractState, token_id: u256) -> bool {
            let current_timestamp: u64 = get_execution_info_syscall().unwrap().unbox().block_info.block_timestamp;
            self.token_expiries.entry(token_id).read() > current_timestamp
        }

        #[external(v0)]
        fn set_details(ref self: ContractState, name: ByteArray, metadata: ByteArray) {
            self.ownable.assert_only_owner();
            self.name.write(name);
            self.metadata.write(metadata);
        }
    }
}
