const config = require("dotenv").config();

require("@nomicfoundation/hardhat-foundry");
require("@nomicfoundation/hardhat-toolbox");
require("@dgma/hardhat-sol-bundler");
const { ZeroHash } = require("ethers");
const deployments = require("./deployment.config");

if (config.error) {
  console.error(config.error);
}

const deployerAccounts = [config?.parsed?.PRIVATE_KEY || ZeroHash];

const DEFAULT_RPC = "https:random.com";

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    compilers: [{ version: "0.8.20" }],
    metadata: {
      appendCBOR: false,
    },
  },
  paths: {
    sources: "src",
    tests: "test",
  },
  networks: {
    hardhat: {
      deployment: deployments.hardhat,
    },
    localhost: {
      deployment: deployments.localhost,
    },
    mainnet: {
      url: config?.parsed?.MAINNET_RPC || DEFAULT_RPC,
      accounts: deployerAccounts,
      deployment: deployments.mainnet,
    },
  },
  etherscan: {
    apiKey: {
      mainnet: config?.parsed?.ETHERSCAN_API_KEY,
    },
  },
};
