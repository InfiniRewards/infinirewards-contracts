import {
  deployContract,
  executeDeployCalls,
  exportDeployments,
  deployer,
  declareContract,
} from "./deploy-contract";
import { green } from "./helpers/colorize-log";

/**
 * Deploy a contract using the specified parameters.
 *
 * @example (deploy contract with contructorArgs)
 * const deployScript = async (): Promise<void> => {
 *   await deployContract(
 *     {
 *       contract: "YourContract",
 *       contractName: "YourContractExportName",
 *       constructorArgs: {
 *         owner: deployer.address,
 *       },
 *       options: {
 *         maxFee: BigInt(1000000000000)
 *       }
 *     }
 *   );
 * };
 *
 * @example (deploy contract without contructorArgs)
 * const deployScript = async (): Promise<void> => {
 *   await deployContract(
 *     {
 *       contract: "YourContract",
 *       contractName: "YourContractExportName",
 *       options: {
 *         maxFee: BigInt(1000000000000)
 *       }
 *     }
 *   );
 * };
 *
 *
 * @returns {Promise<void>}
 */
const deployScript = async (): Promise<void> => {
  // Declare InfiniRewardsPoints contract
  const pointsClassHash = await declareContract({
    contract: "InfiniRewardsPoints",
  });
  console.log("InfiniRewardsPoints class hash:", pointsClassHash);

  // Declare InfiniRewardsCollectible contract
  const collectibleClassHash = await declareContract({
    contract: "InfiniRewardsCollectible",
  });
  console.log("InfiniRewardsCollectible class hash:", collectibleClassHash);

  // Declare InfiniRewardsUserAccount contract
  const userAccountClassHash = await declareContract({
    contract: "InfiniRewardsUserAccount",
  });
  console.log("InfiniRewardsUserAccount class hash:", userAccountClassHash);

  // Declare InfiniRewardsMerchantAccount contract
  const merchantAccountClassHash = await declareContract({
    contract: "InfiniRewardsMerchantAccount",
  });
  console.log(
    "InfiniRewardsMerchantAccount class hash:",
    merchantAccountClassHash
  );

  // Declare InfiniRewardsCertificate contract
  const certificateClassHash = await declareContract({
    contract: "InfiniRewardsCertificate",
  });
  console.log(
    "InfiniRewardsCertificate class hash:",
    certificateClassHash
  );

  // Deploy InfiniRewardsFactory contract
  await deployContract({
    contract: "InfiniRewardsFactory",
    constructorArgs: {
      infini_rewards_points_hash: pointsClassHash.classHash,
      infini_rewards_collectible_hash: collectibleClassHash.classHash,
      infini_rewards_user_account_hash: userAccountClassHash.classHash,
      infini_rewards_merchant_account_hash: merchantAccountClassHash.classHash,
      infini_rewards_certificate_hash: certificateClassHash.classHash,
      owner: deployer.address,
    },
  });
};

deployScript()
  .then(async () => {
    await executeDeployCalls();
    exportDeployments();

    console.log(green("All Setup Done"));
  })
  .catch(console.error);
