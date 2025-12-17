import { RpcProvider, Account } from 'starknet';
import * as dotenv from 'dotenv';

dotenv.config();

const SEPOLIA_RPC = process.env.RPC_URL_SEPOLIA || 'https://free-rpc.nethermind.io/sepolia-juno';
const POINTS_CONTRACT = '0xcf25cecfeec84001c49d9adc7f1be42faf82797b5b2a6c141cc0f76ad83c2';

// Current owner (merchant)
const MERCHANT_ADDRESS = '0x5a7b6dabddac46ef9d5bd89f03470f8cd05431e67ca89b3a97435467bbcb8b7';
const MERCHANT_PRIVATE_KEY = '0x0717a417ec910ab35962f802bcde8c0657228a980987e116d6a31bdc7a957ca7';

// New owner (master - the only account with funds)
const MASTER_ADDRESS = process.env.MASTER_ACCOUNT_ADDRESS || '0x021837708732Bd71423261A9dB2cCca1fdAA19c9400ba50Bb2fb097B7cE3E050';

async function transferOwnership() {
  const provider = new RpcProvider({ nodeUrl: SEPOLIA_RPC });

  console.log('🔄 Transferring Points Contract Ownership to Master Account\n');
  console.log(`Points Contract: ${POINTS_CONTRACT}`);
  console.log(`From (Merchant): ${MERCHANT_ADDRESS}`);
  console.log(`To (Master):     ${MASTER_ADDRESS}\n`);

  // Check current owner
  const ownerResult = await provider.callContract({
    contractAddress: POINTS_CONTRACT,
    entrypoint: 'owner',
    calldata: [],
  });

  console.log(`Current owner: ${ownerResult[0]}\n`);

  if (ownerResult[0].toLowerCase() === MASTER_ADDRESS.toLowerCase()) {
    console.log('✅ Master account is already the owner!');
    return;
  }

  // Create merchant account (current owner)
  const merchantAccount = new Account({
    address: MERCHANT_ADDRESS,
    signer: MERCHANT_PRIVATE_KEY,
    provider,
  });

  console.log('📝 Calling transfer_ownership...');

  // Transfer ownership
  const { transaction_hash } = await merchantAccount.execute({
    contractAddress: POINTS_CONTRACT,
    entrypoint: 'transfer_ownership',
    calldata: [MASTER_ADDRESS],
  });

  console.log(`Transaction hash: ${transaction_hash}`);
  console.log('⏳ Waiting for transaction...');

  await provider.waitForTransaction(transaction_hash);

  // Verify new owner
  const newOwnerResult = await provider.callContract({
    contractAddress: POINTS_CONTRACT,
    entrypoint: 'owner',
    calldata: [],
  });

  console.log(`\n✅ Ownership transferred!`);
  console.log(`New owner: ${newOwnerResult[0]}`);
  console.log(`\n🎉 Master account now owns the contract and will pay all gas fees!`);
}

transferOwnership().catch(console.error);
