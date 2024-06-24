const ethers = require("ethers");

// These constants must match the ones used in the smart contract.
const SIGNING_DOMAIN_NAME = "RedShilliz";
const SIGNING_DOMAIN_VERSION = "1";
const SALT = "642515956091025061967938595111600838978365676";

/**
 * JSDoc typedefs.
 *
 * @typedef {object} NFTVoucher
 * @property {ethers.BigNumber | number} tokenId the id of the un-minted NFT
 * @property {ethers.BigNumber | number} minPrice the minimum price (in wei) that the creator will accept to redeem this NFT
 * @property {ethers.BytesLike} signature an EIP-712 signature of all fields in the NFTVoucher, apart from signature itself.
 */

/**
 * LazyMinter is a helper class that creates NFTVoucher objects and signs them, to be redeemed later by the LazyNFT contract.
 */
class LazyMinter {
  /**
   * Create a new LazyMinter targeting a deployed instance of the LazyNFT contract.
   *
   * @param {Object} options
   * @param {ethers.Contract} contract an ethers Contract that's wired up to the deployed contract
   * @param {ethers.Signer} signer a Signer whose account is authorized to mint NFTs on the deployed contract
   */
  constructor({ contract, signer }) {
    this.contract = contract;
    this.signer = signer;
  }

  /**
   * Creates a new NFTVoucher object and signs it using this LazyMinter's signing key.
   * @param {offerer | string} you
   * @param {offer | object} offer (itemType,  tokenAddress, startAmount, endAmount ): what you're willing to spend — itemType 0 for ETH, 1 for ERC20s 2 for ERC721s, 3 for ERC1155s
   * @param {consideration | number} consideration  (itemType, tokenAddress, startAmount, endAmount, recipient ): what will be received: you should be the recipient of the first item
   * @param {tokenId | object} tokenId
   * @returns {NFTVoucher}
   */
  async createVoucher(tokenAddress, offerer, listingPrice, sellerEarning, serviceFee, startTime, endTime, tokenId, tokenStandard, salt = SALT,) {
    const voucher = { tokenAddress, offerer, listingPrice, sellerEarning, serviceFee, startTime, endTime, tokenId, tokenStandard, salt }
    const domain = await this._signingDomain()
    const types = {
      NFTVoucher: [
        { name: "tokenAddress", type: "address" },
        { name: "offerer", type: "address" },
        { name: "listingPrice", type: "uint256" },
        { name: "sellerEarning", type: "uint256" },
        { name: "serviceFee", type: "uint256" },
        { name: "startTime", type: "uint256" },
        { name: "endTime", type: "uint256" },
        { name: "tokenId", type: "uint256" },
        { name: "salt", type: "string" },
        { name: "tokenStandard", type: "string" }
      ]
    }
    const signature = await this.signer._signTypedData(domain, types, voucher)
    return {
      ...voucher,
      signature,
    }
  }

  /**
   * @private
   * @returns {object} the EIP-721 signing domain, tied to the chainId of the signer
   */
  async _signingDomain() {
    if (this._domain != null) {
      return this._domain;
    }
    const chainId = await this.contract.getChainID()
    this._domain = {
      name: SIGNING_DOMAIN_NAME,
      version: SIGNING_DOMAIN_VERSION,
      verifyingContract: this.contract.address,
      chainId,
    };
    return this._domain;
  }
}

module.exports = {
  LazyMinter
}