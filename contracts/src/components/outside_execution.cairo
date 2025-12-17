// SPDX-License-Identifier: MIT
// SNIP-9: Outside Execution Component (Simplified)

#[starknet::interface]
pub trait IOutsideExecution<TState> {
    fn execute_from_outside_v2(
        ref self: TState,
        caller: starknet::ContractAddress,
        nonce: felt252,
        execute_after: u64,
        execute_before: u64,
        calls: Array<starknet::account::Call>,
        signature: Array<felt252>,
    ) -> Array<Span<felt252>>;

    fn is_valid_outside_execution_nonce(
        self: @TState,
        nonce: felt252
    ) -> bool;
}

#[starknet::component]
pub mod OutsideExecutionComponent {
    use starknet::{get_caller_address, get_block_timestamp, account::Call};
    use starknet::storage::{Map, StorageMapReadAccess, StorageMapWriteAccess};
    use core::num::traits::Zero;

    #[storage]
    pub struct Storage {
        outside_execution_nonces: Map<felt252, bool>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        OutsideExecutionExecuted: OutsideExecutionExecuted,
    }

    #[derive(Drop, starknet::Event)]
    pub struct OutsideExecutionExecuted {
        pub nonce: felt252,
        pub caller: starknet::ContractAddress,
    }

    const ANY_CALLER: felt252 = 'ANY_CALLER';

    #[embeddable_as(OutsideExecutionImpl)]
    impl OutsideExecutionMethods<
        TContractState,
        +HasComponent<TContractState>,
        impl Account: contracts::components::account::AccountComponent::ISRC6<TContractState>,
    > of super::IOutsideExecution<ComponentState<TContractState>> {
        fn execute_from_outside_v2(
            ref self: ComponentState<TContractState>,
            caller: starknet::ContractAddress,
            nonce: felt252,
            execute_after: u64,
            execute_before: u64,
            calls: Array<Call>,
            signature: Array<felt252>,
        ) -> Array<Span<felt252>> {
            // 1. Validate caller
            let actual_caller = get_caller_address();
            assert(
                caller.is_zero()
                || caller == actual_caller
                || caller.into() == ANY_CALLER,
                'OE: invalid caller'
            );

            // 2. Validate timestamp window
            let block_timestamp = get_block_timestamp();
            assert(
                block_timestamp >= execute_after,
                'OE: execution too early'
            );
            assert(
                block_timestamp <= execute_before,
                'OE: execution too late'
            );

            // 3. Validate and consume nonce
            assert(
                !self.outside_execution_nonces.read(nonce),
                'OE: nonce already used'
            );
            self.outside_execution_nonces.write(nonce, true);

            // 4. Verify signature
            let hash = self.compute_hash(caller, nonce, execute_after, execute_before, calls.span());
            let is_valid: felt252 = Account::is_valid_signature(
                self.get_contract(),
                hash,
                signature
            );
            assert(is_valid == starknet::VALIDATED, 'OE: invalid signature');

            // 5. Execute calls
            let mut results = array![];
            let calls_len = calls.len();
            let mut i: u32 = 0;
            loop {
                if i >= calls_len {
                    break;
                }
                match calls.get(i) {
                    Option::Some(call) => {
                        let call = call.unbox();
                        match starknet::syscalls::call_contract_syscall(
                            *call.to,
                            *call.selector,
                            *call.calldata
                        ) {
                            Result::Ok(result) => {
                                results.append(result);
                            },
                            Result::Err(_err) => {
                                let mut error_msg = array!['OE: call ', i.into(), ' failed'];
                                panic(error_msg);
                            }
                        }
                    },
                    Option::None => {
                        break;
                    }
                }
                i += 1;
            };

            // Emit event
            self.emit(OutsideExecutionExecuted {
                nonce,
                caller: actual_caller,
            });

            results
        }

        fn is_valid_outside_execution_nonce(
            self: @ComponentState<TContractState>,
            nonce: felt252
        ) -> bool {
            !self.outside_execution_nonces.read(nonce)
        }
    }

    #[generate_trait]
    pub impl InternalImpl<
        TContractState,
        +HasComponent<TContractState>,
    > of InternalTrait<TContractState> {
        fn compute_hash(
            self: @ComponentState<TContractState>,
            caller: starknet::ContractAddress,
            nonce: felt252,
            execute_after: u64,
            execute_before: u64,
            calls: Span<Call>,
        ) -> felt252 {
            // SNIP-12 compliant typed data hashing
            let mut hash_data = array![
                // Type hash for OutsideExecution
                'OutsideExecution',
                caller.into(),
                nonce,
                execute_after.into(),
                execute_before.into(),
                calls.len().into(),
            ];

            // Hash each call with its complete data
            for call in calls {
                hash_data.append((*call.to).into());
                hash_data.append(*call.selector);
                hash_data.append((*call.calldata).len().into());

                // Include all calldata
                for data in *call.calldata {
                    hash_data.append(*data);
                }
            };

            core::poseidon::poseidon_hash_span(hash_data.span())
        }
    }
}
