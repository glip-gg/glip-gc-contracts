var holders = require('./gc_holders.json');

const { ethers } = require("hardhat");
const hre = require("hardhat");

let blacklistedUsers = [
  '0xeE0d6C5379eeEbd193473feEecfefc3eCFA98d90',
  '0x29004af00E2455E883Ad73A13F9E5fF30f98c6F5',
  '0x0ea481f1E2452bBC96d0B05cC93b85890D488548'
]

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

// 505 -> 1505 -> done
// 1505 -> 2000 -> done
// 2000 -> 2500 -> done
// 2500 -> 3000 -> done
// 3000 -> 3500 -> done

let index = 11000;
async function main() {

  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address); 

  const airdropContract = new ethers.Contract('0xFc4d3713B64CF42d79B30B10ac0d74e3124BC6d0', airdropAbi, deployer);

  let airdropUsers = holders.filter((holder) => {
    return holder.Balance > 20
  }).map((holder) => {
    return {
      croakWalletId: holder.HolderAddress,
      gc: holder.Balance
    }
  }).slice(index)

  try {
    console.log(airdropUsers.length)
    let batchUsers = airdropUsers.slice(0, 500)

    console.log(batchUsers)

    let addresses = batchUsers.map((user) => user.croakWalletId)
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
