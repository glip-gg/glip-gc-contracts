var holders = require('./GC.json');

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

  const airdropContract = new ethers.Contract('0xbCE290199b7688ec3402fB54cc3a7f8a5790c54B', airdropAbi, deployer);

  // let airdropUsers = holders.map((holder) => {
  //   return {
  //     croakWalletId: holder.wallet,
  //     gc: holder.balance
  //   }
  // })

  let airdropUsers = [{
    "croakWalletId":  "0x5F56F6865006eC780085225A241874C4dfb61053",
    "gc": '1000'
  }]

  try {
    console.log(airdropUsers.length)
    let batchUsers = airdropUsers.slice(0, 100)

    // console.log(batchUsers)

    let addresses = batchUsers.filter((user) => ethers.utils.isAddress(user.croakWalletId) && user.gc < 5000).map((user) => user.croakWalletId)
    
    let amounts = batchUsers.map((user) => ethers.utils.parseEther(parseInt(user.gc).toString()))
    console.log(addresses)
    console.log(amounts)
    let tx = await airdropContract.airdrop(addresses, amounts);
    console.log(tx)

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
