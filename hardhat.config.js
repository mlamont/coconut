/** @type import('hardhat/config').HardhatUserConfig */
require("@nomicfoundation/hardhat-ethers");
require("@nomicfoundation/hardhat-verify");
require("@openzeppelin/hardhat-upgrades");
require("dotenv").config();
require("@nomicfoundation/hardhat-chai-matchers");
require("solidity-coverage");

const PRIVATE_KEY = process.env.PRIVATE_KEY;

module.exports = {
  solidity: {
    version: "0.8.28",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000,
      },
    },
  },
  networks: {
    mainnet: {
      // url: `https://eth-mainnet.g.alchemy.com/v2/${process.env.alchemyApiKey}`,
      url: `https://mainnet.infura.io/v3/${process.env.infuraApiKey}`,
      from: "0x1B23c1D7Ad49C9c3bdCAA4d7696496C87cc777b7",
      accounts: [PRIVATE_KEY],
      gasPrice: "auto", // Let hardhat determine gas price
      timeout: 120000, // Increase timeout for mainnet
      confirmations: 2, // Wait for 2 confirmations
    },
    sepolia: {
      // url: `https://eth-sepolia.g.alchemy.com/v2/${process.env.alchemyApiKey}`,
      url: `https://sepolia.infura.io/v3/${process.env.infuraApiKey}`,
      from: "0x1B23c1D7Ad49C9c3bdCAA4d7696496C87cc777b7",
      accounts: [PRIVATE_KEY],
      gasPrice: "auto", // Let hardhat determine gas price
      timeout: 120000, // Increase timeout for mainnet
      confirmations: 2, // Wait for 2 confirmations
    },
  },
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey: process.env.etherscanApiKey,
  },
};
