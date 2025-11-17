const { ethers, upgrades } = require("hardhat");
async function main() {
  const deployeraddress = "0x1B23c1D7Ad49C9c3bdCAA4d7696496C87cc777b7";
  const Coconut = await ethers.getContractFactory("CoconutV01");
  console.log("Deploying Coconut...");
  const coconut = await upgrades.deployProxy(Coconut, [deployeraddress], {
    initializer: "initialize",
    kind: "uups",
    timeout: 120000,
    gasLimit: 5000000,
  });
  await coconut.waitForDeployment();
  console.log("Coconut deployed to:", await coconut.getAddress()); // (PPP)
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
