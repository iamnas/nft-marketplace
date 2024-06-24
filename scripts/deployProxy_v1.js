const { ethers, upgrades } = require("hardhat");

async function main() {
  const gas = await ethers.provider.getGasPrice()
  const NFTMarket_V1 = await ethers.getContractFactory("NFTMarket_V1");
  const proxy = await upgrades.deployProxy(NFTMarket_V1, ["0x434625De08115697975acf741Ac42A8b10656FdD"], { gasPrice: gas, initializer: "initialize" });
  await proxy.deployed();

  console.log(proxy.address);
}

main();
