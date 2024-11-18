import { ethers } from "hardhat";
const { getSelectors } = require('../utils/genSelectors.ts');

const addFacet = async (diamondName: string, diamondAddress: any, facetName: string, facetAddress: any) => {
    // get function selectors from facet contract
    const Facet = await ethers.getContractFactory(facetName);
    const selectors = getSelectors(Facet);

    // fetch contract
    const diamondContract = await ethers.getContractAt(diamondName, diamondAddress);

    const cut = [[facetAddress, 0, selectors]];

    let tx = await diamondContract.diamondCut(cut, "0x0000000000000000000000000000000000000000", "0x")
    console.log('Diamond cut tx:', tx.hash)
    const receipt = await tx.wait()
    if (!receipt.status) {
        throw Error(`[ERROR] Diamond cut add failed: ${tx.hash}`)
    }
    console.log('[SUCCESS] Completed diamond cut');
}

const removeFacet = async (diamondName: string, diamondAddress: any, facetName: string) => {
    // get function selectors from facet contract
    const Facet = await ethers.getContractFactory(facetName);
    const selectors = getSelectors(Facet);

    // fetch contract
    const diamondContract = await ethers.getContractAt(diamondName, diamondAddress);

    const cut = [['0x0000000000000000000000000000000000000000',2,selectors]];

    let tx = await diamondContract.diamondCut(cut, "0x0000000000000000000000000000000000000000", "0x")
    console.log('Diamond cut tx:', tx.hash)
    const receipt = await tx.wait()
    if (!receipt.status) {
        throw Error(`[ERROR] Diamond cut add failed: ${tx.hash}`)
    }
    console.log('[SUCCESS] Completed diamond cut');
}

module.exports = {
    addFacet,
    removeFacet
}