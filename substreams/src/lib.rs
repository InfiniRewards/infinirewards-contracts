mod pb;
mod abi;

use pb::starknet::v1::*;
use pb::sf::substreams::starknet::r#type::v1::Transactions;
use crate::abi::factory_contract::Event;

use substreams::Hex;
use starknet::core::types::{Felt, EmittedEvent};
use substreams::log;

#[substreams::handlers::map]
fn map_factory_events(transactions: Transactions) -> Result<Events, substreams::errors::Error> {
    let mut events = Events::default();
    
    for transaction in transactions.transactions_with_receipt {
        let data = transaction.receipt.unwrap();

        for event in data.events {
            let event_from_address = Hex(event.from_address.as_slice()).to_string();
            
            // Check if event is from factory contract
            if event_from_address != "6c0b75d53c757cc1979d3aaa9482ac449ae0dfd1e5a9807b24478cf4da2d5f8" {
                continue;
            }

            // Convert event data
            let mut data_felts = vec![];
            let mut keys_felts = vec![];
            for key in event.keys {
                keys_felts.push(Felt::from_bytes_be_slice(key.as_slice()));
            }
            for bytes in event.data {
                data_felts.push(Felt::from_bytes_be_slice(bytes.as_slice()));
            }

            let emitted_event = EmittedEvent {
                from_address: Felt::from_bytes_be_slice(event.from_address.as_slice()),
                keys: keys_felts,
                data: data_felts,
                block_hash: None,
                block_number: None,
                transaction_hash: Felt::default(),
            };

            // Parse factory event
            if let Ok(factory_event) = Event::try_from(emitted_event) {
                // Check if it's a MerchantCreated event
                if let Event::MerchantCreated(merchant_data) = factory_event {
                    // Convert ContractAddress to string representation
                    let merchant_felt: Felt = merchant_data.merchant.into();
                    let points_felt: Felt = merchant_data.points_contract.into();
                    
                    events.merchant_contracts.push(MerchantContract {
                        merchant_address: format!("0x{:064x}", merchant_felt),
                        points_contract: format!("0x{:064x}", points_felt),
                    });
                }
            }
        }
    }

    Ok(events)
}
