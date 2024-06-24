
const { ethers, upgrades } = require("hardhat");
//the address of the deployed proxy
const PROXY = "PROXY-ADDRESS";

async function main() {
    const NFTMarket_V2 = await ethers.getContractFactory("NFTMarket_V2");
    console.log("Upgrading NFTMarket_V2...");
    await upgrades.upgradeProxy(PROXY, NFTMarket_V2);
    console.log("NFTMarket_V2 upgraded");
}

main();