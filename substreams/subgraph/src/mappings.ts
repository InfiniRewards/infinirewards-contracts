import { Protobuf } from "as-proto/assembly";
import { Events as protoEvents } from "./pb/starknet/v1/Events";
import { Merchant } from "../generated/schema";
import { BigInt, log } from "@graphprotocol/graph-ts";

export function handleTriggers(bytes: Uint8Array): void {
  const input = Protobuf.decode<protoEvents>(bytes, protoEvents.decode);
  
  for (let i = 0; i < input.merchantContracts.length; i++) {
    const merchantData = input.merchantContracts[i];
    
    // Create new merchant entity
    let merchant = new Merchant(merchantData.merchantAddress);
    
    merchant.merchantAddress = merchantData.merchantAddress;
    merchant.pointsContract = merchantData.pointsContract;
    
    merchant.save();
    
    log.info(
      'Created merchant {} with points contract {}',
      [merchant.merchantAddress, merchant.pointsContract]
    );
  }
}
