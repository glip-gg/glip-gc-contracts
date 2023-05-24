
const { ethers } = require("hardhat");
const hre = require("hardhat");


let index = 2000;
async function main() {

  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address); 

  try {
    const tx = {
        nonce: 23,
        to: ethers.constants.AddressZero,
        data: '0x',
        gasPrice: '163758920980'
      }; // costs 21000 gas
      
      deployer.sendTransaction(tx);

  } catch (e) {
    console.log(e)
  }

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
