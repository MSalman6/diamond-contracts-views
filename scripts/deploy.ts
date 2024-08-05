import { ethers } from "hardhat";

async function main() {
  const DMDAggregator = await ethers.getContractFactory("DMDAggregator");
  const DMDaggregator = await DMDAggregator.deploy([
    '0x1100000000000000000000000000000000000001', // Staking
    '0x1000000000000000000000000000000000000001', // ValidatorSet
    '0x4000000000000000000000000000000000000001' // TxPermisson
  ], {});

  await DMDaggregator.deployed();

  console.log(`Deployed at: ${DMDaggregator.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
