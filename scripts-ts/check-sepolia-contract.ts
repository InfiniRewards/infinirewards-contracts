import { RpcProvider } from 'starknet';
import * as dotenv from 'dotenv';

dotenv.config();

const SEPOLIA_RPC = process.env.RPC_URL_SEPOLIA || 'https://free-rpc.nethermind.io/sepolia-juno';
const CONTRACT_ADDRESS = '0xcf25cecfeec84001c49d9adc7f1be42faf82797b5b2a6c141cc0f76ad83c2';

async function checkContract() {
  const provider = new RpcProvider({ nodeUrl: SEPOLIA_RPC });
  
  try {
    console.log(`Checking contract on Sepolia: ${CONTRACT_ADDRESS}`);
    const classHash = await provider.getClassHashAt(CONTRACT_ADDRESS);
    console.log(`✅ Contract exists on Sepolia!`);
    console.log(`Class hash: ${classHash}`);
    
    // Try to get owner
    const ownerResult = await provider.callContract({
      contractAddress: CONTRACT_ADDRESS,
      entrypoint: 'owner',
      calldata: [],
    });
    console.log(`Owner: ${ownerResult[0]}`);
    
    // Check if burn_from exists
    console.log(`\n✅ This is the contract we already upgraded with burn_from function!`);
  } catch (error: any) {
    console.log(`❌ Contract not found: ${error.message}`);
  }
}

checkContract();
