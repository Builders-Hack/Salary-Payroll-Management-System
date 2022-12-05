import { ethers } from "hardhat";

async function main() {

// USDC token contract is deployed to: 0x99E11732C5488Ad4b85ed93E46d23b46e736E6f9
   //Payroll contract is deployed to: 0xEF1ea81Bc1F49fD73F359DBfB59164bF461c622d

  ////////DEPLOYING THE TOKEN CONTRACT
  const USDC = await ethers.getContractFactory("USDC");
  const usdc = await USDC.deploy();

  await usdc.deployed();

  console.log("USDC token contract is deployed to:", usdc.address);


   ////////DEPLOYING THE PAYROLL CONTRACT
   const companyManager = "0x637CcDeBB20f849C0AA1654DEe62B552a058EA87";
   const PayRoll = await ethers.getContractFactory("Payroll");
   const payroll = await PayRoll.deploy(companyManager , usdc.address);
 
   await payroll.deployed();
 
   console.log("Payroll contract is deployed to:", payroll.address);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

//checkings