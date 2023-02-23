const { ethers } = require("hardhat");
const hre = require("hardhat");

let airdropAbi = [
    {
        "inputs": [
          {
            "internalType": "address",
            "name": "_user",
            "type": "address"
          }
        ],
        "name": "getBlackListStatus",
        "outputs": [
          {
            "internalType": "bool",
            "name": "",
            "type": "bool"
          }
        ],
        "stateMutability": "view",
        "type": "function"
      },
      {
        "inputs": [
          {
            "internalType": "address",
            "name": "_evilUser",
            "type": "address"
          }
        ],
        "name": "addBlackList",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
      }
]

async function main() {

  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address); 

  const tokenContract = new ethers.Contract('0x4fb20c8410bfbf6045fb1b3211b6b8ddf9e125ee', airdropAbi, deployer);

  try {
    let blacklisted = await tokenContract.addBlackList('0xBB16CCfbEDF10848B26add3D1d534724C3107E9d')
    console.log(blacklisted)
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
