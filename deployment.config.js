const { VerifyPlugin } = require("@dgma/hardhat-sol-bundler/plugins/Verify");

const config = {
  Miller: {},
};

module.exports = {
  hardhat: {
    config: config,
  },
  localhost: { lockFile: "./local.deployment-lock.json", config: config },
  mainnet: {
    lockFile: "./deployment-lock.json",
    verify: true,
    plugins: [VerifyPlugin],
    config: config,
  },
};
