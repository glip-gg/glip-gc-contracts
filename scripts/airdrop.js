let airdropUsers = []

const { ethers } = require("hardhat");
const hre = require("hardhat");

let airdropAbi = [
    {
        "inputs": [
          {
            "internalType": "address[]",
            "name": "users",
            "type": "address[]"
          },
          {
            "internalType": "uint256[]",
            "name": "amounts",
            "type": "uint256[]"
          }
        ],
        "name": "airdrop",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
      }
]

async function main() {

  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address); 

  const airdropContract = new ethers.Contract('0x6DA86D3e60F84247CbD40E76D22A7bc517026298', airdropAbi, deployer);

  try {
    let batchUsers = airdropUsers.slice(0, 100)
    let addresses = batchUsers.filter((user) => ethers.utils.isAddress(user.croakWalletId)).map((user) => user.croakWalletId)
    let amounts = batchUsers.map((user) => ethers.utils.parseEther(user.gc.toString()))
    console.log(addresses)
    console.log(amounts)
    await airdropContract.estimateGas.airdrop(addresses, amounts);
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
