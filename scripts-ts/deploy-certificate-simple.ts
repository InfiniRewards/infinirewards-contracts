import { CallData, stark, Account, RpcProvider } from "starknet";
import yargs from "yargs";
import fs from "fs";
import path from "path";
import dotenv from "dotenv";
import { green, red, yellow } from "./helpers/colorize-log";

// Load environment variables
dotenv.config({ path: path.resolve(__dirname, "../.env") });

interface Arguments {
  network: string;
  owner?: string;
  name: string;
  metadata: string;
  classHash?: string;
  [x: string]: unknown;
  _: (string | number)[];
  $0: string;
}

const deployCertificate = async () => {
  const argv = yargs(process.argv.slice(2))
    .option("network", {
      type: "string",
      description: "Specify the network (devnet, sepolia, mainnet)",
      demandOption: true,
    })
    .option("owner", {
      type: "string",
      description: "Owner address for the certificate contract",
      demandOption: false,
    })
    .option("name", {
      type: "string",
      description: "Name of the certificate collection",
      demandOption: true,
    })
    .option("metadata", {
      type: "string",
      description: "Metadata URI for the certificate collection",
      demandOption: true,
    })
    .option("class-hash", {
      type: "string",
      description: "Class hash of the InfiniRewardsCertificate contract",
      demandOption: false,
    })
    .parseSync() as Arguments;

  const networkName: string = argv.network;
  const name: string = argv.name;
  const metadata: string = argv.metadata;
  let classHash: string | undefined = argv.classHash;

  // Setup provider and account based on network
  let provider: RpcProvider;
  let account: Account;

  if (networkName === "sepolia") {
    const rpcUrl = process.env.RPC_URL_SEPOLIA;
    const accountAddress = process.env.ACCOUNT_ADDRESS_SEPOLIA;
    const privateKey = process.env.PRIVATE_KEY_SEPOLIA;

    if (!rpcUrl || !accountAddress || !privateKey) {
      throw new Error("Missing Sepolia network configuration in .env file");
    }

    provider = new RpcProvider({ nodeUrl: rpcUrl });
    account = new Account(provider, accountAddress, privateKey);
  } else if (networkName === "mainnet") {
    const rpcUrl = process.env.RPC_URL_MAINNET;
    const accountAddress = process.env.ACCOUNT_ADDRESS_MAINNET;
    const privateKey = process.env.PRIVATE_KEY_MAINNET;

    if (!rpcUrl || !accountAddress || !privateKey) {
      throw new Error("Missing Mainnet network configuration in .env file");
    }

    provider = new RpcProvider({ nodeUrl: rpcUrl });
    account = new Account(provider, accountAddress, privateKey);
  } else if (networkName === "devnet") {
    const rpcUrl = process.env.RPC_URL_DEVNET || "http://127.0.0.1:5050";
    const accountAddress = process.env.ACCOUNT_ADDRESS_DEVNET || "0x64b48806902a367c8598f4f95c305e8c1a1acba5f082d294a43793113115691";
    const privateKey = process.env.PRIVATE_KEY_DEVNET || "0x71d7bb07b9a64f6f78ac4c816aff4da9";

    provider = new RpcProvider({ nodeUrl: rpcUrl });
    account = new Account(provider, accountAddress, privateKey);
  } else {
    throw new Error(`Network ${networkName} not supported. Use 'sepolia', 'mainnet', or 'devnet'.`);
  }

  // Use the provided owner address or default to deployer address
  const ownerAddress: string = argv.owner || account.address;

  console.log(yellow(`Deploying InfiniRewardsCertificate on ${networkName}`));
  console.log(yellow(`Owner: ${ownerAddress}`));
  console.log(yellow(`Name: ${name}`));
  console.log(yellow(`Metadata: ${metadata}`));

  try {
    // If no class hash provided, try to read from deployments
    if (!classHash) {
      const deploymentsPath = path.resolve(
        __dirname,
        `../deployments/${networkName}_latest.json`
      );

      if (fs.existsSync(deploymentsPath)) {
        const deployments = JSON.parse(fs.readFileSync(deploymentsPath, "utf8"));
        if (deployments.InfiniRewardsCertificate?.classHash) {
          classHash = deployments.InfiniRewardsCertificate.classHash;
          console.log(yellow(`Using class hash from deployments: ${classHash}`));
        } else {
          throw new Error(
            "InfiniRewardsCertificate class hash not found. Please provide --class-hash or declare the contract first."
          );
        }
      } else {
        throw new Error(
          "Deployment file not found. Please provide --class-hash or declare the contract first."
        );
      }
    }

    // Read the contract ABI
    const contractClassPath = path.resolve(
      __dirname,
      "../contracts/target/dev/contracts_InfiniRewardsCertificate.contract_class.json"
    );

    if (!fs.existsSync(contractClassPath)) {
      throw new Error(
        "Contract class file not found. Please compile the contracts first with 'yarn compile'"
      );
    }

    const contractClass = JSON.parse(fs.readFileSync(contractClassPath, "utf8"));
    const abi = contractClass.abi;

    // Prepare constructor calldata
    const calldata = new CallData(abi);
    const constructorCalldata = calldata.compile("constructor", {
      owner: ownerAddress,
      name: name,
      metadata: metadata,
    });

    console.log(yellow("Deploying certificate contract..."));

    // Generate a unique salt
    const salt = stark.randomAddress();

    // Build the deployment call using UDC
    const deployCall = {
      contractAddress: "0x041a78e741e5af2fec34b695679bc6891742439f7afb8484ecd7766661ad02bf", // UDC address
      entrypoint: "deployContract",
      calldata: [
        classHash,           // class_hash
        salt,               // salt
        "0x0",              // unique
        constructorCalldata.length.toString(), // calldata_len
        ...constructorCalldata  // calldata
      ]
    };

    // Execute the deployment
    console.log(yellow("Sending deployment transaction..."));
    const deployTx = await account.execute(deployCall);

    console.log(yellow(`Transaction hash: ${deployTx.transaction_hash}`));
    console.log(yellow("Waiting for transaction confirmation..."));

    // Wait for the transaction
    const receipt = await provider.waitForTransaction(deployTx.transaction_hash);

    // Extract the deployed address from the transaction receipt
    let deployedAddress = "";
    if (receipt && 'events' in receipt) {
      const events = (receipt as any).events;
      // Look for the ContractDeployed event from UDC
      if (events && Array.isArray(events)) {
        for (const event of events) {
          if (event.from_address === "0x041a78e741e5af2fec34b695679bc6891742439f7afb8484ecd7766661ad02bf") {
            // UDC emits the deployed address in the event data
            if (event.data && event.data.length > 0) {
              deployedAddress = event.data[0];
              break;
            }
          }
        }
      }
    }

    if (!deployedAddress) {
      console.log(yellow("Could not extract deployed address from events."));
      console.log(yellow("Please check the transaction on Starkscan to get the deployed address."));
      deployedAddress = "Check transaction on explorer";
    }

    console.log(green("Certificate contract deployed successfully!"));
    console.log(green(`Certificate address: ${deployedAddress}`));
    console.log(green(`Transaction hash: ${deployTx.transaction_hash}`));

    // Save deployment info
    const deploymentInfo = {
      network: networkName,
      certificateAddress: deployedAddress,
      classHash: classHash,
      owner: ownerAddress,
      name,
      metadata,
      deployedAt: new Date().toISOString(),
      transactionHash: deployTx.transaction_hash,
    };

    // Save to deployments directory
    const deploymentsDir = path.resolve(__dirname, "../deployments");
    if (!fs.existsSync(deploymentsDir)) {
      fs.mkdirSync(deploymentsDir, { recursive: true });
    }

    const certificateDeploymentPath = path.resolve(
      deploymentsDir,
      `certificate_${networkName}_${Date.now()}.json`
    );

    fs.writeFileSync(
      certificateDeploymentPath,
      JSON.stringify(deploymentInfo, null, 2)
    );

    console.log(green(`Deployment info saved to: ${certificateDeploymentPath}`));

    return deploymentInfo;
  } catch (error) {
    console.error(red("Error deploying certificate contract:"), error);
    throw error;
  }
};

// Execute if run directly
if (require.main === module) {
  deployCertificate()
    .then(() => {
      console.log(green("Certificate deployment completed successfully!"));
      process.exit(0);
    })
    .catch((error) => {
      console.error(red("Certificate deployment failed:"), error);
      process.exit(1);
    });
}

export { deployCertificate };