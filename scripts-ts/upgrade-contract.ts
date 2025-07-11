import { Contract, Call } from "starknet";
import { networks } from "./helpers/networks";
import yargs from "yargs";
import fs from "fs";
import path from "path";
import { green, red, yellow } from "./helpers/colorize-log";
import { declareScript } from "./declare";

interface Arguments {
  network: string;
  address: string;
  classHash?: string;
  updateComponents?: boolean;
  declare?: boolean;
  [x: string]: unknown;
  _: (string | number)[];
  $0:string;
}

const upgradeContract = async () => {
  const argv = yargs(process.argv.slice(2))
    .option("network", {
      type: "string",
      description: "Specify the network",
      demandOption: true,
    })
    .option("address", {
      type: "string",
      description: "The address of the contract to upgrade",
      demandOption: true,
    })
    .option("class-hash", {
      type: "string",
      description: "The new class hash to upgrade to",
      demandOption: false,
    })
    .option("update-components", {
      type: "boolean",
      description: "Update the component class hashes in the factory",
      default: false,
    })
    .option("declare", {
      type: "boolean",
      description: "Declare all contracts before upgrading/updating",
      default: false,
    })
    .parseSync() as Arguments;

  const networkName: string = argv.network;
  const contractAddress: string = argv.address;
  let newClassHash: string | undefined = argv.classHash;
  const updateComponents: boolean = argv.updateComponents;
  const shouldDeclare: boolean = argv.declare;

  if (shouldDeclare) {
    console.log(yellow("Declaring all contracts first..."));
    await declareScript();
    console.log(green("Declaration complete."));
  }

  if (!newClassHash && !updateComponents) {
    console.log(
      yellow(
        "No explicit action provided (--class-hash or --update-components). Assuming update based on declared contracts."
      )
    );
  }

  if (!newClassHash && updateComponents) {
    console.log(
      yellow("Class hash not provided, only updating components...")
    );
  } else if (!newClassHash) {
    console.log(
      yellow("New class hash not provided, reading from deployment file...")
    );
    const deploymentsPath = path.resolve(
      __dirname,
      `../deployments/${networkName}_latest.json`
    );
    if (fs.existsSync(deploymentsPath)) {
      const deployments = JSON.parse(
        fs.readFileSync(deploymentsPath, "utf8")
      );
      if (deployments.InfiniRewardsFactory) {
        newClassHash = deployments.InfiniRewardsFactory.classHash;
      }
    }
  }

  if (!newClassHash && !updateComponents) {
    console.error(
      red(
        "Could not find new class hash. Please provide it with the --class-hash flag or ensure it exists in the deployment file."
      )
    );
    return;
  }

  console.log(yellow(`Target contract address: ${contractAddress}`));

  const { provider, deployer } = networks[networkName];

  if (!deployer || !provider) {
    throw new Error(
      `Network configuration not found for "${networkName}". Check your scripts-ts/helpers/networks.ts file and that your .env file is set up correctly.`
    );
  }

  const { abi: contractAbi } = await provider.getClassAt(contractAddress);

  if (!contractAbi) {
    throw new Error(`Could not get ABI for contract at ${contractAddress}`);
  }

  const contract = new Contract(contractAbi, contractAddress, deployer);
  const calls: Call[] = [];

  if (newClassHash) {
    console.log(yellow(`Preparing upgrade to class hash: ${newClassHash}`));
    calls.push(
      contract.populate("upgrade", {
        new_class_hash: newClassHash,
      })
    );
  }

  if (updateComponents) {
    console.log(yellow("Preparing to update component hashes..."));
    const deploymentsPath = path.resolve(
      __dirname,
      `../deployments/${networkName}_latest.json`
    );
    if (!fs.existsSync(deploymentsPath)) {
      throw new Error(
        `Could not find deployment file at ${deploymentsPath}. Make sure you have deployed the contracts first.`
      );
    }
    const deployments = JSON.parse(fs.readFileSync(deploymentsPath, "utf8"));

    const components = [
      { name: "InfiniRewardsPoints", setter: "set_points_class_hash" },
      {
        name: "InfiniRewardsCollectible",
        setter: "set_collectible_class_hash",
      },
      {
        name: "InfiniRewardsCertificate",
        setter: "set_certificate_class_hash",
      },
      {
        name: "InfiniRewardsUserAccount",
        setter: "set_user_class_hash",
      },
      {
        name: "InfiniRewardsMerchantAccount",
        setter: "set_merchant_class_hash",
      },
    ];

    for (const component of components) {
      if (
        deployments[component.name] &&
        deployments[component.name].classHash
      ) {
        console.log(
          yellow(
            `Found ${component.name} with hash: ${
              deployments[component.name].classHash
            }`
          )
        );
        calls.push(
          contract.populate(component.setter, [
            deployments[component.name].classHash,
          ])
        );
      } else {
        console.log(
          yellow(
            `Skipping ${component.name} as it was not found in the deployment file.`
          )
        );
      }
    }
  }

  if (calls.length === 0) {
    console.log(yellow("No actions to perform. Exiting."));
    return;
  }

  console.log(yellow("Executing transaction..."));

  const { transaction_hash } = await deployer.execute(calls);

  console.log(yellow("Waiting for transaction to be accepted..."));
  await provider.waitForTransaction(transaction_hash, {
    retryInterval: 5000,
  });

  console.log(green("Transaction successful!"));
  console.log(green(`Transaction hash: ${transaction_hash}`));
};

upgradeContract().catch((e) => {
  console.error(red("Error during contract operation:"), e);
  process.exit(1);
}); 