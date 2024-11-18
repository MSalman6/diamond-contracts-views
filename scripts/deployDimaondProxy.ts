import { ethers } from "hardhat";
const { addFacet } = require('../utils/diamondUtils');
const { getSelectors } = require('../utils/genSelectors');

async function main() {
    // Deploy the Diamond Proxy
    const AggregatorDiamond = await ethers.getContractFactory("AggregatorDiamond");
    const aggregatorDiamond = await AggregatorDiamond.deploy();
    await aggregatorDiamond.waitForDeployment();
    console.log(`Deployed Diamond Proxy at: ${await aggregatorDiamond.getAddress()}`);

    // Deploy the Implementation facet
    const DMDAggregator = await ethers.getContractFactory("DMDAggregator");
    const dmdAggregator = await DMDAggregator.deploy();
    await dmdAggregator.waitForDeployment();
    console.log(`Deployed Implementation facet at: ${await dmdAggregator.getAddress()}`);

    // Add the implementation facet selectors to the diamond proxy
    await addFacet("AggregatorDiamond", await aggregatorDiamond.getAddress(), 'DMDAggregator', await dmdAggregator.getAddress());
    console.log(`Added DMDAggregator facet to Diamond Proxy`);

    // Call initialize on the diamond proxy
    const diamond = await ethers.getContractAt('AggregatorDiamond', String(await aggregatorDiamond.getAddress()));
    const initializeTx = await diamond.initialize(
        '0x1100000000000000000000000000000000000001', // Staking
        '0x1000000000000000000000000000000000000001', // ValidatorSet
        '0x4000000000000000000000000000000000000001' // TxPermisson
    );
    const callbackReceipt = await initializeTx.wait();
    console.log(`Diamond Proxy initialized successfully: ${callbackReceipt.transactionHash}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});