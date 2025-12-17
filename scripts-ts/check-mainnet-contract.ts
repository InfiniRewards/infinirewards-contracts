import { RpcProvider } from 'starknet';
import * as dotenv from 'dotenv';

dotenv.config();

const MAINNET_RPC = process.env.STARKNET_RPC_URL || 'https://starknet-mainnet.public.blastapi.io';
const CONTRACT_ADDRESS = '0xcf25cecfeec84001c49d9adc7f1be42faf82797b5b2a6c141cc0f76ad83c2';

async function checkContract() {
  const provider = new RpcProvider({ nodeUrl: MAINNET_RPC });
  
  try {
    console.log(`Checking contract: ${CONTRACT_ADDRESS}`);
    const classHash = await provider.getClassHashAt(CONTRACT_ADDRESS);
    console.log(`✅ Contract exists! Class hash: ${classHash}`);
    
    // Try to get owner
    const ownerResult = await provider.callContract({
      contractAddress: CONTRACT_ADDRESS,
      entrypoint: 'owner',
      calldata: [],
    });
    console.log(`Owner: ${ownerResult[0]}`);
  } catch (error: any) {
    console.log(`❌ Contract not found or error: ${error.message}`);
  }
}

checkContract();
