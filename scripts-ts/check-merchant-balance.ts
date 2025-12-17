import { RpcProvider } from 'starknet';
import * as dotenv from 'dotenv';

dotenv.config();

const SEPOLIA_RPC = process.env.RPC_URL_SEPOLIA || 'https://free-rpc.nethermind.io/sepolia-juno';
const STRK_ADDRESS = '0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d';
const MERCHANT_ADDRESS = '0x5a7b6dabddac46ef9d5bd89f03470f8cd05431e67ca89b3a97435467bbcb8b7';

async function checkBalance() {
  const provider = new RpcProvider({ nodeUrl: SEPOLIA_RPC });

  console.log('💰 Checking merchant account balance...\n');
  console.log(`Merchant: ${MERCHANT_ADDRESS}`);
  console.log(`STRK Token: ${STRK_ADDRESS}\n`);

  try {
    const result = await provider.callContract({
      contractAddress: STRK_ADDRESS,
      entrypoint: 'balanceOf',
      calldata: [MERCHANT_ADDRESS],
    });

    const balanceLow = BigInt(result[0]);
    const balanceHigh = BigInt(result[1]);
    const balanceWei = balanceLow + (balanceHigh << BigInt(128));
    const balanceStrk = Number(balanceWei) / 1e18;

    console.log(`Balance (wei): ${balanceWei}`);
    console.log(`Balance (STRK): ${balanceStrk.toFixed(6)} STRK`);

    if (balanceStrk < 0.1) {
      console.log(`\n⚠️  WARNING: Low balance! Recommend funding with at least 1 STRK for gas fees.`);
    } else {
      console.log(`\n✅ Balance looks good!`);
    }

    return balanceStrk;
  } catch (error) {
    console.error('Error checking balance:', error);
    return null;
  }
}

checkBalance().catch(console.error);
