require('@openzeppelin/hardhat-upgrades');
require('dotenv').config();

task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

module.exports = {
  // defaultNetwork: "ropsten",
  networks: {
    ropsten: {
      url: `https://ropsten.infura.io/v3/${process.env.infuraId}`,
      accounts: [process.env.privateKey]
    },
    mainnet: {
      url: `https://mainnet.infura.io/v3/${process.env.infuraId}`,
      accounts: [process.env.privateKey]
    },
    kovan: {
      url: `https://kovan.infura.io/v3/${process.env.infuraId}`,
      accounts: [process.env.privateKey]
    },
    rinkeby: {
      url: `https://rinkeby.infura.io/v3/${process.env.infuraId}`,
      accounts: [process.env.privateKey]
    },
    sepolia: {
      url: `https://ethereum-sepolia.blockpi.network/v1/rpc/public`,
      accounts: [process.env.privateKey]
    },
    binance_testnet: {
      url: `https://data-seed-prebsc-1-s1.binance.org:8545`,
      accounts: [process.env.privateKey]
    },
    binance_mainnet: {
      url: `https://bsc-dataseed1.binance.org`,
      accounts: [process.env.privateKey]
    },
    polygon_mumbai: {
      url: `https://polygon-mumbai.g.alchemy.com/v2/q0CodUz-CMg8vtiOhtrzzc8sriN_Sbsq`,
      accounts: [process.env.privateKey]
    },
    polygon_mainnet: {
      url: ``,
      accounts: [process.env.privateKey]
    }
  },
  etherscan: {
    apiKey: process.env.POLYGONSCAN_API_KEY
  },
  solidity: {
    version: "0.8.9",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  mocha: {
    timeout: 100000000
  }
};