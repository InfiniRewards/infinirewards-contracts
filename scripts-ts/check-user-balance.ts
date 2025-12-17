import { RpcProvider } from 'starknet';
import * as dotenv from 'dotenv';

dotenv.config();

const SEPOLIA_RPC = process.env.RPC_URL_SEPOLIA || 'https://free-rpc.nethermind.io/sepolia-juno';
const POINTS_CONTRACT = '0xcf25cecfeec84001c49d9adc7f1be42faf82797b5b2a6c141cc0f76ad83c2';
const USER_ADDRESS = '0x34740dbf6a7c064c412f5bfb92fbbef5231621f3e1dec9bdab5f0c588af18c';

async function checkBalance() {
  const provider = new RpcProvider({ nodeUrl: SEPOLIA_RPC });

  console.log('🔍 Checking user balance on blockchain...\n');
  console.log(`User: ${USER_ADDRESS}`);
  console.log(`Points Contract: ${POINTS_CONTRACT}\n`);

  try {
    const result = await provider.callContract({
      contractAddress: POINTS_CONTRACT,
      entrypoint: 'balanceOf',
      calldata: [USER_ADDRESS],
    });

    const balanceLow = BigInt(result[0]);
    const balanceHigh = BigInt(result[1]);
    const balance = balanceLow + (balanceHigh << BigInt(128));

    console.log(`Balance (u256): low=${balanceLow}, high=${balanceHigh}`);
    console.log(`Balance (decimal): ${balance} points`);

    return balance;
  } catch (error) {
    console.error('Error checking balance:', error);
    return null;
  }
}

checkBalance().catch(console.error);
