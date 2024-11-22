import { ethers } from "hardhat";
import { verifyContract } from "../utils/deployment";

async function deploy() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying from: ", deployer.address);

  const args = [
    deployer.address,
    '0x1100000000000000000000000000000000000001',  // Staking
    '0x1000000000000000000000000000000000000001',   // ValidatorSet
    '0x4000000000000000000000000000000000000001', // TxPermisson
  ];

  // Deploy the DMDAggregator contract
  const DMDAggregator = await ethers.getContractFactory('DMDAggregator');
  const dmdAggregator = await DMDAggregator.deploy(
    args[0],
    args[1],
    args[2],
    args[3]
  );

  await dmdAggregator.waitForDeployment();
  console.log("DMDAggregator deployed at: ", await dmdAggregator.getAddress());
  console.log("Verifying DMDAggregator contract...");

  await verifyContract(dmdAggregator, args, 60);
  console.log("Done.");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
deploy().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
