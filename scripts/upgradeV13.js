const { ethers, upgrades } = require("hardhat");
async function main() {
  const PeachLatest = await ethers.getContractFactory("PeachV13");
  console.log("Upgrading Peach...");

  await upgrades.upgradeProxy(
    "0x06Aa0754629e138d5bE04EE800cf2A6F41Aa24D0",
    PeachLatest
  );
  console.log("Peach upgraded"); /// PPP address remains
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
