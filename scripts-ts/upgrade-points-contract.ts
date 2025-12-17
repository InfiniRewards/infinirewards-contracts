import { RpcProvider, Account } from 'starknet';
import * as dotenv from 'dotenv';

dotenv.config();

const SEPOLIA_RPC = process.env.RPC_URL_SEPOLIA || 'https://free-rpc.nethermind.io/sepolia-juno';
const POINTS_CONTRACT = '0xcf25cecfeec84001c49d9adc7f1be42faf82797b5b2a6c141cc0f76ad83c2';
const NEW_CLASS_HASH = '0x6c277778245b3ae4453ce3f2a39c4a9c730c041e121908ef066586e3f73c3a2'; // With burn_from

// Merchant account that owns the points contract (retrieved from database)
const MERCHANT_ADDRESS = '0x5a7b6dabddac46ef9d5bd89f03470f8cd05431e67ca89b3a97435467bbcb8b7';
const MERCHANT_PRIVATE_KEY = '0x0717a417ec910ab35962f802bcde8c0657228a980987e116d6a31bdc7a957ca7';

async function upgradePointsContract() {
  const provider = new RpcProvider({ nodeUrl: SEPOLIA_RPC });
  
  console.log(`\n🔍 Upgrading POINTS contract: ${POINTS_CONTRACT}`);
  
  // Get current class hash
  const currentClassHash = await provider.getClassHashAt(POINTS_CONTRACT);
  console.log(`Current class hash: ${currentClassHash}`);
  console.log(`Target class hash:  ${NEW_CLASS_HASH}`);
  
  if (currentClassHash === NEW_CLASS_HASH) {
    console.log(`\n✅ Points contract already has burn_from function!`);
    return;
  }
  
  console.log(`\n⚠️  Upgrading points contract...`);

  // Create merchant account (owner of the contract)
  const account = new Account({
    address: MERCHANT_ADDRESS,
    signer: MERCHANT_PRIVATE_KEY,
    provider,
  });
  
  // Get owner
  const ownerResult = await provider.callContract({
    contractAddress: POINTS_CONTRACT,
    entrypoint: 'owner',
    calldata: [],
  });
  
  console.log(`Contract owner: ${ownerResult[0]}`);
  console.log(`Upgrade account: ${MERCHANT_ADDRESS}`);
  
  // Execute upgrade
  console.log(`\nCalling upgrade...`);
  const { transaction_hash } = await account.execute({
    contractAddress: POINTS_CONTRACT,
    entrypoint: 'upgrade',
    calldata: [NEW_CLASS_HASH],
  });
  
  console.log(`📝 Transaction hash: ${transaction_hash}`);
  console.log(`Waiting for transaction...`);
  
  await provider.waitForTransaction(transaction_hash);
  
  console.log(`\n✅ Upgrade successful!`);
  
  // Verify
  const newClassHash = await provider.getClassHashAt(POINTS_CONTRACT);
  if (newClassHash === NEW_CLASS_HASH) {
    console.log(`🎉 Points contract now has burn_from function!`);
  } else {
    console.log(`❌ Verification failed`);
  }
}

upgradePointsContract().catch(console.error);
