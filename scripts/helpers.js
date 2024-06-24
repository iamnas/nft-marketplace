const { ethers } = require("ethers");
const fs = require("fs");
const { CONTRACT_DEPLOYMENT_WALLET_PRIVATE_KEY } = process.env;

const chainConfigFilePath = "./config-chains.json";
// Helper method for fetching a connection provider to the Ethereum network
function getAvailableChains() {
  let chainConfigRaw = fs.readFileSync(chainConfigFilePath);

  let chainConfigs = JSON.parse(chainConfigRaw);
  return chainConfigs;
}

const hardHatSettings = {
  networks: {
    mumbai: {
      url: `https://matic-mumbai.chainstacklabs.com/`,
      accounts: [
        `cfc8c888f539cecb307d35a31fdfd37e67d4de185fa8f68dd36d9749d24050b6`,
      ],
      chainId: 80001,
    },

    goerli: {
      url: `https://eth-goerli.api.onfinality.io/public`,
      accounts: [
        `cfc8c888f539cecb307d35a31fdfd37e67d4de185fa8f68dd36d9749d24050b6`,
      ],
      chainId: 5,
    },

    sepolia: {
      url: `https://ethereum-sepolia.blockpi.network/v1/rpc/public`,
      accounts: [
        `cfc8c888f539cecb307d35a31fdfd37e67d4de185fa8f68dd36d9749d24050b6`,
      ],
      chainId: 11155111,
    },
  },
};

// Helper method for fetching a connection provider to the Ethereum network
function getNetworkSetting(chainId) {
  return Object.values(hardHatSettings.networks).find(
    (chainSettings) => chainSettings.chainId == chainId
  );
}

// Helper method for fetching a connection provider to the Ethereum network
function getProvider(chainId) {
  const hardhatChainNetwork = getNetworkSetting(chainId);
  return ethers.getDefaultProvider(hardhatChainNetwork?.url);
}

// Helper method for fetching a wallet account using an environment variable for the PK
function getWallet(chainId, provider) {
  const hardhatChainNetwork = getNetworkSetting(chainId);
  if (!hardhatChainNetwork) {
    console.error(
      "\x1b[33m%s\x1b[0m",
      `No matching chainId found for network: '${chainId}', using localhost.`
    );
    return null;
  }
  return new ethers.Wallet(
    hardhatChainNetwork ? hardhatChainNetwork.accounts[0] : "",
    provider
  );
}

module.exports = {
  getAvailableChains,
  chainConfigFilePath,
  hardHatSettings,
  getProvider,
  getWallet,
  getNetworkSetting,
};
