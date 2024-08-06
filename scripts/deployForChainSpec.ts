import { ethers } from "hardhat";
import fs from "fs";

async function deployForChainspec() {

    const DMDAggregator = await ethers.getContractFactory("DMDAggregator");
    
    const staking = '0x1100000000000000000000000000000000000001'; // Staking
    const validatorSet = '0x1000000000000000000000000000000000000001'; // ValidatorSet
    const txPermisson = '0x4000000000000000000000000000000000000001' // TxPermisson

    let spec:  { [id: string] : any; }  = {};

    const viewAddress = "0x9990000000000000000000000000000000000000"; 
    spec[viewAddress] =  {
        balance: "0",
        constructor: (await DMDAggregator.getDeployTransaction(staking, validatorSet, txPermisson)).data
    };

    //console.log("output:");
    //console.log(JSON.stringify(output));

    const outDir = "out";

    if (!fs.existsSync(outDir)) {
        fs.mkdirSync(outDir);
    }

    fs.writeFileSync("out/spec_views.json", JSON.stringify(spec));
}

deployForChainspec();