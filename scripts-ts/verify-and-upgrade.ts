import { RpcProvider, Account } from 'starknet';
import * as dotenv from 'dotenv';

dotenv.config();

const SEPOLIA_RPC = process.env.RPC_URL_SEPOLIA || 'https://free-rpc.nethermind.io/sepolia-juno';
const CONTRACT_ADDRESS = '0x06c0b75d53c757cc1979d3aaa9482ac449ae0dfd1e5a9807b24478cf4da2d5f8';
const NEW_CLASS_HASH = '0x6c277778245b3ae4453ce3f2a39c4a9c730c041e121908ef066586e3f73c3a2'; // With burn_from

async function verifyAndUpgrade() {
  const provider = new RpcProvider({ nodeUrl: SEPOLIA_RPC });
  
  console.log(`\n🔍 Checking contract: ${CONTRACT_ADDRESS}`);
  
  // Get current class hash
  const currentClassHash = await provider.getClassHashAt(CONTRACT_ADDRESS);
  console.log(`Current class hash: ${currentClassHash}`);
  console.log(`Target class hash:  ${NEW_CLASS_HASH}`);
  
  if (currentClassHash === NEW_CLASS_HASH) {
    console.log(`\n✅ Contract already upgraded with burn_from function!`);
    return;
  }
  
  console.log(`\n⚠️  Contract needs upgrade. Upgrading now...`);
  
  // Create account
  const accountAddress = process.env.ACCOUNT_ADDRESS_SEPOLIA || process.env.MASTER_ACCOUNT_ADDRESS;
  const privateKey = process.env.PRIVATE_KEY_SEPOLIA || process.env.MASTER_ACCOUNT_PRIVATE_KEY;
  
  if (!accountAddress || !privateKey) {
    throw new Error('Account credentials not found in environment');
  }
  
  const account = new Account({
    address: accountAddress,
    signer: privateKey,
    provider,
  });
  
  // Execute upgrade
  console.log(`Calling upgrade with class hash: ${NEW_CLASS_HASH}`);
  const { transaction_hash } = await account.execute({
    contractAddress: CONTRACT_ADDRESS,
    entrypoint: 'upgrade',
    calldata: [NEW_CLASS_HASH],
  });
  
  console.log(`\n📝 Transaction hash: ${transaction_hash}`);
  console.log(`Waiting for transaction...`);
  
  await provider.waitForTransaction(transaction_hash);
  
  console.log(`\n✅ Upgrade successful!`);
  
  // Verify upgrade
  const newClassHash = await provider.getClassHashAt(CONTRACT_ADDRESS);
  console.log(`Verified class hash: ${newClassHash}`);
  
  if (newClassHash === NEW_CLASS_HASH) {
    console.log(`\n🎉 Contract successfully upgraded with burn_from function!`);
  } else {
    console.log(`\n❌ Upgrade verification failed`);
  }
}

verifyAndUpgrade().catch(console.error);
