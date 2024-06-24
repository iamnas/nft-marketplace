# Sample Hardhat Project

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, and a script that deploys that contract.

Try running some of the following tasks:

```shell
npx hardhat accounts
npx hardhat compile
npx hardhat clean
npx hardhat test
npx hardhat node
npx hardhat help


npx hardhat run --network polygon_mumbai scripts/deployProxy_v1.js

npx hardhat verify --network polygon_mumbai "contract address"
npx hardhat verify --network polygon_mumbai 0x504543b3525642bdD3c80C21E2937AfD955E84b9

```

# Notes

To getting started with new contract, follow below steps

- Add your contract address private key in the CONTRACT_DEPLOYMENT_WALLET_PRIVATE_KEY in the .env file.
- If you modified the contract then run below command
  - npx hardhat compile
- Then run below command to deploy contract on the network
  - npx hardhat deploy --chain-id chainId (e.g. chainId 5 for goerli)
- Once deployment is completed you can see the contract address updated in config-chains.json file as well as in console like
  `NFTMarket deployed to Ethereum(Goerli):0x3b37a9ed02d81270a3f688a5c02615dd02d9d09d 
View in block explorer: https://goerli.etherscan.io//address/0x3b37a9ed02d81270a3f688a5c02615dd02d9d09d`
- Use this contract addresses in the application.

- DEPLOY : npx hardhat run --network polygon_mumbai scripts/deployProxy_v1.js

- VERIFY : npx hardhat verify --network polygon_mumbai "contract address"
-          npx hardhat verify --network polygon_mumbai 0x504543b3525642bdD3c80C21E2937AfD955E84b9

# How to use the NFTMarket contract in the application

- The NFTMarket contract exposes below public functions
  1.  createToken(string memory tokenURI, uint256 tokenId) - Create and mint token
  2.  createMarketItem(uint256 tokenId, uint256 price) - List the item for sale.
  3.  unListMarketItem(uint256 tokenId) - Unlists an item previously listed for sell and transfer back to the seller.
  4.  resellToken(uint256 tokenId, uint256 price) - Resell purchased token for new price
  5.  createMarketSale(uint256 tokenId) - Sell the token and transfer it to new owner
  6.  redeem(address redeemer, NFTVoucher calldata voucher) - Redeems an NFTVoucher for an actual NFT, creating and minting it in the process.
