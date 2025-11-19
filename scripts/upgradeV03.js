const { ethers, upgrades } = require("hardhat");
async function main() {
  const CoconutLatest = await ethers.getContractFactory("CoconutV03");
  console.log("Upgrading Coconut...");

  await upgrades.upgradeProxy(
    "0xd3f70B1a7C1E2b936664e6752976Fdd6330D9023",
    CoconutLatest
  );
  console.log("Coconut upgraded"); /// PPP address remains
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
