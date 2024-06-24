// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
// const hre = require("hardhat");
const { task } = require("hardhat/config");
require("@openzeppelin/hardhat-upgrades");
const fs = require("fs");
const {
  getAvailableChains,
  chainConfigFilePath,
  getWallet,
} = require("./helpers");

task("deploy:market", "Deploys the Market.sol contract")
  .addParam(
    "chainId",
    "The Chain ID of the blockchain where this contract will be deployed."
  )
  .setAction(async function (taskArguments, hre) {
    const availableChains = getAvailableChains();
    const { chainId } = taskArguments;
    if (!(chainId in availableChains)) {
      let chainsForPrinting = {};
      Object.values(availableChains).forEach((chain) => {
        chainsForPrinting[
          chain.CHAIN_ID
        ] = `${chain.CHAIN_NAME} (${chain.NETWORK_NAME})`;
      });
      chainsForPrinting = JSON.stringify(chainsForPrinting, null, 4);
      console.error(
        "\x1b[31m%s\x1b[0m",
        `Invalid chainId: ${chainId}.\nPlease select one of the following:\n${chainsForPrinting}`
      );
      process.exit(1);
    }
    const wallet = getWallet(chainId);
    let NFTMarket;
    const gas = await ethers.provider.getGasPrice()
  
    if (wallet && wallet.address) {
      console.log("wallet address is", wallet.address)
      NFTMarket = await hre.ethers.getContractFactory(
        "NFTMarket",
        wallet.address
      );
    } else {
      NFTMarket = await hre.ethers.getContractFactory("NFTMarket");
    }
    const nftMarket = await upgrades.deployProxy(NFTMarket, {
      gasPrice: gas, 
      initializer: "initialize",
    });
    await nftMarket.deployed();
    //console.log(nftMarket.address);
    availableChains[chainId].NFT_MARKETPLACE_ADDRESS =
      nftMarket.address.toLowerCase();
    fs.writeFileSync(
      chainConfigFilePath,
      JSON.stringify(availableChains, null, 4)
    );
    const chainConfig = availableChains[chainId];
    console.log(
      "\x1b[32m%s\x1b[0m",
      `NFTMarket deployed to ${chainConfig.CHAIN_NAME} (${chainConfig.NETWORK_NAME}): ${chainConfig.NFT_MARKETPLACE_ADDRESS}`
    );
    console.log(
      "\x1b[32m%s\x1b[0m",
      `View in block explorer: ${chainConfig.BLOCK_EXPLORER_URL}/address/${chainConfig.NFT_MARKETPLACE_ADDRESS}`
    );

    console.log(
      await upgrades.erc1967.getImplementationAddress(nftMarket.address),
      " getImplementationAddress"
    );
    console.log(
      await upgrades.erc1967.getAdminAddress(nftMarket.address),
      " getAdminAddress"
    );
  });

task("deploy", "Deploys the Market.sol and NFT.sol contract")
  .addParam(
    "chainId",
    "The Chain ID of the blockchain where this contract will be deployed."
  )
  .setAction(async (taskArgs, hre) => {
    await hre.run("deploy:market", taskArgs);
  });
