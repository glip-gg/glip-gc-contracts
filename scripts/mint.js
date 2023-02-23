
const { ethers } = require("hardhat");
const hre = require("hardhat");

let mintAbi = [
    {
        "inputs": [
          {
            "internalType": "address",
            "name": "to",
            "type": "address"
          },
          {
            "internalType": "uint256",
            "name": "amount",
            "type": "uint256"
          },
          {
            "internalType": "string",
            "name": "mintTag",
            "type": "string"
          }
        ],
        "name": "mintGC",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
      }
]

async function main() {

  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address); 

  const airdropContract = new ethers.Contract('0xad3958ae18dfc973a88beeaf17d4e722f92d952d', mintAbi, deployer);

  try {


    let tx = await airdropContract.estimateGas.mintGC("0xD5cF6015b588cabB3D6a0A36F94b2f9dE901969B", ethers.utils.parseEther('30'), "play-purchase");
    console.log(tx.hash)

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
