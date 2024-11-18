import { ethers } from "hardhat";
import { deployProxy, verifyContract } from "../utils/deployment";

async function deploy() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying from: ", deployer.address);
  console.log("Deploying DMDAggregator contract");

  const args = [
    deployer.address,
    '0x1100000000000000000000000000000000000001', // Staking
    '0x1000000000000000000000000000000000000001', // ValidatorSet
    '0x4000000000000000000000000000000000000001' // TxPermisson
  ]

  // Deploy the DMDAggregator contract using a proxy for upgradeability
  const dao = await deployProxy("DMDAggregator", args);

  await dao.waitForDeployment();

  console.log("DMDAggregator deployed at: ", await dao.getAddress());

  console.log("Verifying DMDAggregator contract");

  await verifyContract(dao, args, 60);

  console.log("Done.");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
deploy().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
