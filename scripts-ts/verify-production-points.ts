import { RpcProvider } from 'starknet';
import * as dotenv from 'dotenv';

dotenv.config();

const SEPOLIA_RPC = process.env.RPC_URL_SEPOLIA || 'https://free-rpc.nethermind.io/sepolia-juno';
const POINTS_CONTRACT = '0xcf25cecfeec84001c49d9adc7f1be42faf82797b5b2a6c141cc0f76ad83c2';
const EXPECTED_CLASS_HASH = '0x6c277778245b3ae4453ce3f2a39c4a9c730c041e121908ef066586e3f73c3a2';

async function verify() {
  const provider = new RpcProvider({ nodeUrl: SEPOLIA_RPC });

  console.log('🔍 Verifying production points contract...\n');
  console.log(`Contract: ${POINTS_CONTRACT}`);

  const classHash = await provider.getClassHashAt(POINTS_CONTRACT);
  console.log(`Current class hash: ${classHash}`);
  console.log(`Expected class hash: ${EXPECTED_CLASS_HASH}`);

  if (classHash === EXPECTED_CLASS_HASH) {
    console.log('\n✅ Production points contract has burn_from function!');
    return true;
  } else {
    console.log('\n❌ Class hash mismatch');
    return false;
  }
}

verify().then(success => process.exit(success ? 0 : 1)).catch(console.error);
