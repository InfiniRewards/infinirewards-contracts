import {
  CairoContract,
  CompiledSierra,
  Contract,
  Provider,
  uint256,
  Abi,
} from "starknet";
import { red, yellow } from "./colorize-log";
import { Network } from "../types";
import { isString } from "util";

export const erc20ABI = [
  {
    inputs: [
      {
        name: "account",
        type: "felt",
      },
    ],
    name: "balanceOf",
    outputs: [
      {
        name: "balance",
        type: "Uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
] satisfies Abi;

//function to decide preferred token for fee payment
export async function getTxVersion(
  network: Network,
  feeToken: string,
  isSierra?: boolean
) {
  const { feeToken: feeTokenOptions, provider, deployer } = network;

  // For RPC 0.8, we must use V3 transactions which require STRK
  // Force STRK for v3 transactions
  const strkToken = feeTokenOptions.find((token) => token.name === "strk");

  if (strkToken) {
    const balance = await getBalance(
      deployer.address,
      provider,
      strkToken.address
    );
    if (balance > 0n) {
      console.log(yellow(`Using STRK as fee token (required for v3 transactions)`));
      return TransactionVersion.V3;
    }
    console.log(
      red(`STRK balance is zero. V3 transactions require STRK for fees. Please fund your wallet with STRK.`)
    );
  }

  // For v3 transactions, we can only use STRK
  console.error(
    red(
      "Error: V3 transactions require STRK for fees. Please fund your wallet with STRK on Sepolia."
    )
  );
  throw new Error("V3 transactions require STRK for fees");
}

export async function getBalance(
  account: string,
  provider: Provider,
  tokenAddress: string
): Promise<bigint> {
  // If balance checks are disabled due to networking issues, return a default balance
  if (process.env.SKIP_BALANCE_CHECK === "true") {
    console.log(yellow("Skipping balance check (SKIP_BALANCE_CHECK=true), assuming sufficient balance"));
    return 1000000000000000000n; // Return 1 ETH worth as default
  }

  // Retry logic for network connectivity issues
  let retries = 3;
  let delay = 1000;
  
  while (retries > 0) {
    try {
      const contract = new Contract(erc20ABI, tokenAddress, provider);
      const { balance } = await contract.balanceOf(account);
      return uint256.uint256ToBN(balance);
    } catch (error) {
      if ((error.toString().includes("fetch failed") || error.toString().includes("timeout") || error.toString().includes("ECONNRESET")) && retries > 1) {
        console.log(yellow(`Network error fetching balance, retrying in ${delay}ms... (${retries - 1} attempts left)`));
        await new Promise(resolve => setTimeout(resolve, delay));
        delay *= 2;
        retries--;
      } else {
        console.error("Error fetching balance:", error);
        return 0n;
      }
    }
  }
  return 0n;
}

function getTxVersionFromFeeToken(feeToken: string, isSierra?: boolean) {
  // RPC 0.8 only supports v3 transactions
  // V3 transactions use STRK for fees
  return TransactionVersion.V3;
}

/**
 * V_ Transaction versions HexString
 * F_ Fee Transaction Versions HexString (2 ** 128 + TRANSACTION_VERSION)
 */
export enum TransactionVersion {
  V0 = "0x0",
  V1 = "0x1",
  V2 = "0x2",
  V3 = "0x3",
  F0 = "0x100000000000000000000000000000000",
  F1 = "0x100000000000000000000000000000001",
  F2 = "0x100000000000000000000000000000002",
  F3 = "0x100000000000000000000000000000003",
}
