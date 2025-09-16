import { Contract, CallData, stark, transaction } from "starknet";
import { networks } from "./helpers/networks";
import yargs from "yargs";
import fs from "fs";
import path from "path";
import { green, red, yellow } from "./helpers/colorize-log";
import { declareContract, deployContract, executeDeployCalls, exportDeployments } from "./deploy-contract";

interface Arguments {
  network: string;
  owner?: string;
  name: string;
  metadata: string;
  declare?: boolean;
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
      description: "Owner address for the certificate contract (defaults to deployer address)",
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
    .option("declare", {
      type: "boolean",
      description: "Declare the contract before deploying",
      default: false,
    })
    .parseSync() as Arguments;

  const networkName: string = argv.network;
  const name: string = argv.name;
  const metadata: string = argv.metadata;
  const shouldDeclare: boolean = argv.declare;

  const { provider, deployer } = networks[networkName];

  if (!deployer || !provider) {
    throw new Error(
      `Network configuration not found for "${networkName}". Check your scripts-ts/helpers/networks.ts file and that your .env file is set up correctly.`
    );
  }

  // Use the provided owner address or default to deployer address
  const ownerAddress: string = argv.owner || deployer.address;

  console.log(yellow(`Deploying InfiniRewardsCertificate on ${networkName}`));
  console.log(yellow(`Owner: ${ownerAddress}`));
  console.log(yellow(`Name: ${name}`));
  console.log(yellow(`Metadata: ${metadata}`));

  try {
    let certificateClassHash: string;

    // Declare the contract if needed
    if (shouldDeclare) {
      console.log(yellow("Declaring InfiniRewardsCertificate contract..."));
      const declareResult = await declareContract({
        contract: "InfiniRewardsCertificate",
      });
      certificateClassHash = declareResult.classHash;
      console.log(green(`Certificate contract declared with class hash: ${certificateClassHash}`));
    } else {
      // Try to read from existing deployments
      const deploymentsPath = path.resolve(
        __dirname,
        `../deployments/${networkName}_latest.json`
      );

      if (fs.existsSync(deploymentsPath)) {
        const deployments = JSON.parse(fs.readFileSync(deploymentsPath, "utf8"));
        if (deployments.InfiniRewardsCertificate?.classHash) {
          certificateClassHash = deployments.InfiniRewardsCertificate.classHash;
          console.log(yellow(`Using existing class hash: ${certificateClassHash}`));
        } else {
          throw new Error(
            "InfiniRewardsCertificate class hash not found in deployments. Run with --declare flag."
          );
        }
      } else {
        throw new Error(
          "Deployment file not found. Run with --declare flag to declare the contract first."
        );
      }
    }

    // Deploy the certificate contract
    console.log(yellow("Deploying certificate contract..."));

    // Deploy using the deployContract function with contract name
    const deployResult = await deployContract({
      contract: "InfiniRewardsCertificate",
      constructorArgs: {
        owner: ownerAddress,
        name: name,
        metadata: metadata,
      },
      contractName: `Certificate_${Date.now()}`,
    });

    const certificateAddress = deployResult.address;

    console.log(green("Certificate contract deployed successfully!"));
    console.log(green(`Certificate address: ${certificateAddress}`));

    // Execute the deployment
    await executeDeployCalls();
    await exportDeployments();

    // Save deployment info
    const deploymentInfo = {
      network: networkName,
      certificateAddress,
      classHash: certificateClassHash,
      owner: ownerAddress,
      name,
      metadata,
      deployedAt: new Date().toISOString(),
      transactionHash: "See deployment logs",
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

    // Also update the latest deployments file
    const latestDeploymentsPath = path.resolve(
      deploymentsDir,
      `${networkName}_latest.json`
    );

    let latestDeployments: any = {};
    if (fs.existsSync(latestDeploymentsPath)) {
      latestDeployments = JSON.parse(fs.readFileSync(latestDeploymentsPath, "utf8"));
    }

    // Add certificate deployment to certificates array
    if (!latestDeployments.certificates) {
      latestDeployments.certificates = [];
    }

    latestDeployments.certificates.push({
      address: certificateAddress,
      name,
      metadata,
      owner: ownerAddress,
      deployedAt: new Date().toISOString(),
    });

    fs.writeFileSync(
      latestDeploymentsPath,
      JSON.stringify(latestDeployments, null, 2)
    );

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