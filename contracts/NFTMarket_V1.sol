// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

interface IWETH is IERC20Upgradeable {
    function deposit() external payable;

    function withdraw(uint256) external;
}

interface IERC721 {
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;
}

interface IERC1155 {
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 amount,
        bytes memory data
    ) external;
}

contract NFTMarket_V1 is
    Initializable,
    ERC721Upgradeable,
    ERC721URIStorageUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    EIP712Upgradeable,
    OwnableUpgradeable
{
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIds;
    CountersUpgradeable.Counter private _itemsSold;
    string private constant SIGNING_DOMAIN = "RedShilliz";
    string private constant SIGNATURE_VERSION = "1";
    string private constant ERC721_STANDARD = "ERC721";
    string private constant ERC1155_STANDARD = "ERC1155";

    bool public initialized;
    address public marketPlaceOwner;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address payable owner) public initializer {
        require(!initialized, "already initialized");
        __ERC721_init("RedShilliz Tokens", "RedShilliz");
        __ERC721URIStorage_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        marketPlaceOwner = owner;

        __EIP712_init(SIGNING_DOMAIN, SIGNATURE_VERSION);

        __Ownable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);

        initialized = true;
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(UPGRADER_ROLE) {}

    // The following functions are overrides required by Solidity.

    function _burn(
        uint256 tokenId
    ) internal override(ERC721Upgradeable, ERC721URIStorageUpgradeable) {
        super._burn(tokenId);
    }

    function tokenURI(
        uint256 tokenId
    )
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(
            ERC721Upgradeable,
            ERC721URIStorageUpgradeable,
            AccessControlUpgradeable
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    struct MarketItem {
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    /// @notice Represents an un-minted NFT, which has not yet been recorded into the blockchain. A signed voucher can be redeemed for a real NFT using the redeem function.

    struct NFTVoucher {
        uint256 tokenId;
        bytes signature;
        address offerer;
        address tokenAddress;
        uint256 listingPrice;
        uint256 sellerEarning;
        uint256 serviceFee;
        uint256 startTime;
        uint256 endTime;
        string salt;
        string tokenStandard;
    }

    mapping(uint256 => MarketItem) private idToMarketItem;

    event MarketItemCreated(
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );





    function createToken(
        string memory _tokenURI,
        uint256 tokenId
    ) public payable returns (uint256) {
        require(!_exists(tokenId), "Token already exists");
        _mint(msg.sender, tokenId);
        _setTokenURI(tokenId, _tokenURI);
        return tokenId;
    }

    function getMarketItemByTokenId(
        uint256 tokenId
    ) public view returns (MarketItem memory) {
        return idToMarketItem[tokenId];
    }

    /// @notice Redeems an NFTVoucher for an actual NFT, creating it in the process.
    /// @param redeemer The address of the account which will receive the NFT upon success.
    /// @param voucher A signed NFTVoucher that describes the NFT to be redeemed.

    function redeem(
        address redeemer,
        string calldata tokenUri,
        NFTVoucher calldata voucher
    ) public payable returns (uint256) {
        // make sure signature is valid and get the address of the signer

        require(
            block.timestamp >= voucher.startTime &&
                block.timestamp <= voucher.endTime,
            "Listing is either expired or not started yet."
        );

        address signer = _verify(voucher);

        require(
            msg.value >= voucher.listingPrice,
            "Insufficient funds to redeem"
        );

        if (!_exists(voucher.tokenId)) {
            // first assign the token to the signer, to establish provenance on-chain
            _mint(signer, voucher.tokenId);
            _setTokenURI(voucher.tokenId, tokenUri);
        } else {
            // check that the signer is the current owner of the NFT
            require(
                ownerOf(voucher.tokenId) == signer,
                "Signer must be current owner of NFT"
            );
        }

        //before transfer lets create entry in our contract
        idToMarketItem[voucher.tokenId] = MarketItem(
            voucher.tokenId,
            payable(signer),
            payable(redeemer),
            voucher.listingPrice,
            true
        );

        // Transfer the sellingamount amount to seller
        idToMarketItem[voucher.tokenId].seller.transfer(voucher.sellerEarning);

        // transfer the service fee to marketplace owner
        payable(marketPlaceOwner).transfer(voucher.serviceFee);

        _transfer(signer, redeemer, voucher.tokenId);

        _itemsSold.increment();

        emit MarketItemCreated(
            voucher.tokenId,
            signer,
            redeemer,
            voucher.sellerEarning,
            true
        );

        return voucher.tokenId;
    }

    function acceptOffer(
        address wethContractAddress,
        string memory tokenUri,
        NFTVoucher calldata voucher
    ) public payable {
        // make sure signature is valid and get the address of the signer
        address offerer = _verify(voucher);

        uint256 balance = getWethBalance(wethContractAddress, offerer);

        require(
            balance >= voucher.listingPrice,
            string(abi.encodePacked("Buyer has insufficient WETH balance"))
        );

        // bid should not be expired
        require(
            block.timestamp >= voucher.startTime &&
                block.timestamp <= voucher.endTime,
            "Bid is either expired or not started yet."
        );

        if (!_exists(voucher.tokenId)) {
            // if token is not minted already then mint it first
            _mint(msg.sender, voucher.tokenId);
            _setTokenURI(voucher.tokenId, tokenUri);

            //before transfer lets create entry in our contract
            idToMarketItem[voucher.tokenId] = MarketItem(
                voucher.tokenId,
                payable(msg.sender),
                payable(offerer),
                voucher.listingPrice,
                true
            );
        } else {
            require(
                idToMarketItem[voucher.tokenId].owner == msg.sender,
                "Only owner can accept offer"
            );

            idToMarketItem[voucher.tokenId].sold = true;
            idToMarketItem[voucher.tokenId].price = voucher.listingPrice;
        }

        // transfer weth to the user who created token
        IWETH(wethContractAddress).transferFrom(
            offerer,
            msg.sender,
            voucher.sellerEarning
        );

        // transfer service fee to the nft marketplace owner
        IWETH(wethContractAddress).transferFrom(
            offerer,
            marketPlaceOwner,
            voucher.serviceFee
        );

        //transfer to buyer who has highest bid+
        _transfer(msg.sender, offerer, voucher.tokenId);

        //now buyer is the owner of the token
        idToMarketItem[voucher.tokenId].owner = payable(offerer);

        _itemsSold.increment();
        emit MarketItemCreated(
            voucher.tokenId,
            msg.sender,
            offerer,
            voucher.sellerEarning,
            true
        );
    }

    function acceptOtherNftsOffer(
        address wethContractAddress,
        NFTVoucher calldata voucher
    ) public payable {
        // make sure signature is valid and get the address of the signer
        address offerer = _verify(voucher);

        uint256 balance = getWethBalance(wethContractAddress, offerer);

        require(
            balance >= voucher.listingPrice,
            string(abi.encodePacked("Buyer has insufficient WETH balance"))
        );

        // bid should not be expired
        require(
            block.timestamp >= voucher.startTime &&
                block.timestamp <= voucher.endTime,
            "Bid is either expired or not started yet."
        );

        // transfer weth to the user who created token
        IWETH(wethContractAddress).transferFrom(
            offerer,
            msg.sender,
            voucher.sellerEarning
        );

        // transfer service fee to the nft marketplace owner
        IWETH(wethContractAddress).transferFrom(
            offerer,
            marketPlaceOwner,
            voucher.serviceFee
        );

        // transfer to buyer who has highest bid
        // check the token standard and based on that transfer the nft
        if (
            keccak256(abi.encodePacked(voucher.tokenStandard)) ==
            keccak256(abi.encodePacked(ERC721_STANDARD))
        ) {
            IERC721(voucher.tokenAddress).safeTransferFrom(
                msg.sender,
                offerer,
                voucher.tokenId
            );
        } else if (
            keccak256(abi.encodePacked(voucher.tokenStandard)) ==
            keccak256(abi.encodePacked(ERC1155_STANDARD))
        ) {
            IERC1155(voucher.tokenAddress).safeTransferFrom(
                msg.sender,
                offerer,
                voucher.tokenId,
                1,
                ""
            );
        } else {
            revert("Invalid ERC Token standard");
        }
    }

    function redeemOtherNfts(
        address redeemer,
        NFTVoucher calldata voucher
    ) public payable {
        // make sure listing is active
        require(
            block.timestamp >= voucher.startTime &&
                block.timestamp <= voucher.endTime,
            "Listing is either expired or not started yet."
        );

        address signer = _verify(voucher);

        // make sure that the redeemer is paying enough to cover the buyer's cost
        require(
            msg.value >= voucher.listingPrice,
            "Insufficient funds to redeem"
        );

        // Transfer the sellingamount amount to seller
        payable(signer).transfer(voucher.sellerEarning);

        // transfer the service fee to marketplace owner
        payable(marketPlaceOwner).transfer(voucher.serviceFee);

        //check the token standard and based on that transfer the nft
        if (
            keccak256(abi.encodePacked(voucher.tokenStandard)) ==
            keccak256(abi.encodePacked(ERC721_STANDARD))
        ) {
            IERC721(voucher.tokenAddress).safeTransferFrom(
                signer,
                redeemer,
                voucher.tokenId
            );
        } else if (
            keccak256(abi.encodePacked(voucher.tokenStandard)) ==
            keccak256(abi.encodePacked(ERC1155_STANDARD))
        ) {
            IERC1155(voucher.tokenAddress).safeTransferFrom(
                signer,
                redeemer,
                voucher.tokenId,
                1,
                ""
            );
        } else {
            revert("Invalid ERC Token standard");
        }
    }

    /// @notice Verifies the signature for a given NFTVoucher, returning the address of the signer.
    /// @dev Will revert if the signature is invalid. Does not verify that the signer is authorized to mint NFTs.
    /// @param voucher An NFTVoucher describing an unminted NFT.

    function _hash(
        NFTVoucher calldata voucher
    ) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "NFTVoucher(address tokenAddress,address offerer,uint256 listingPrice,uint256 sellerEarning,uint256 serviceFee,uint256 startTime,uint256 endTime,uint256 tokenId,string salt,string tokenStandard)"
                        ),
                        voucher.tokenAddress,
                        voucher.offerer,
                        voucher.listingPrice,
                        voucher.sellerEarning,
                        voucher.serviceFee,
                        voucher.startTime,
                        voucher.endTime,
                        voucher.tokenId,
                        keccak256(bytes(voucher.salt)),
                        keccak256(bytes(voucher.tokenStandard))
                    )
                )
            );
    }

    function getWethBalance(
        address wethContractAddress,
        address userAddress
    ) internal view returns (uint256) {
        return IWETH(wethContractAddress).balanceOf(userAddress);
    }

    function getAllowance(
        address wethContractAddress,
        address userAddress
    ) internal view returns (uint256) {
        return IWETH(wethContractAddress).allowance(userAddress, address(this));
    }

    function getChainID() external view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    function _verify(
        NFTVoucher calldata voucher
    ) internal view returns (address) {
        bytes32 digest = _hash(voucher);
        return ECDSAUpgradeable.recover(digest, voucher.signature);
    }
}
