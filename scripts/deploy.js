// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {

  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address); 

  const GlipGCToken = await hre.ethers.getContractFactory("BtxGCHandler");
  const token = await GlipGCToken.deploy('0x4fb20c8410bFbf6045FB1B3211B6b8dDF9e125eE', '0x4f6143e47e353016b13ABb66b0C962B126C0574e');

  await token.deployed();

  console.log(
    `token deployed to ${token.address}`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
