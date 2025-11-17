const { ethers, upgrades } = require("hardhat");
async function main() {
  // const [deployer] = await ethers.getSigners();
  // ok: what does "getSigners()" return,
  // and: what variable-type is deployer.address - it's a string!
  const deployeraddress = "0x1B23c1D7Ad49C9c3bdCAA4d7696496C87cc777b7";
  const Peach = await ethers.getContractFactory("PeachV14");
  console.log("Deploying Peach...");
  const peach = await upgrades.deployProxy(Peach, [deployeraddress], {
    initializer: "initialize",
    kind: "uups",
    timeout: 120000,
    gasLimit: 5000000,
  });
  await peach.waitForDeployment();
  console.log("Peach deployed to:", await peach.getAddress()); // (PPP)
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
