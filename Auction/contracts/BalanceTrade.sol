pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./TransferProxy.sol";

contract BalanceTrade {
    enum BuyingAssetType { ERC1155 , ERC721}

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event SellerFee(uint8 sellerFee);
    event BuyerFee(uint8 buyerFee);
    event BuyAsset(address indexed assetOwner, uint256 indexed tokenId, uint256 quantity,address indexed buyer);
    event ExecuteBid(address indexed assetOwner, uint256 indexed tokenId, uint256 quantity,address indexed buyer);

    uint8 private buyerFeePermille;
    uint8 private sellerFeePermille;

    TransferProxy public TransferProxy;
    address public owner;
    mapping (uint256=>bool) private usedNonce;
    mapping (uint256=>Asset1155) private users;

    struct Asset1155 {
        address seller;
        address nftAddress;
        uint256 tokenId;
        uint256 supply;
        bool initialize;
    }
    struct Fee {
        uint platformFee;
        uint assetFee;
        uint royalityFee;
        uint price;
        address tokenCreator;
    }
    /** An ECDSA signature */
    struct Sign {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 nonce;
    }
    struct Order {
        address seller;
        address buyer;
        address erc20Address;
        address nftAddress;
        BuyingAssetType nftType;
        uint unitPrice;
        uint amount;
        uint tokenId;
        uint qty;
    }
    modifier onlyOwner {
        require(owner == msg.sender , "Ownable: caller is not the owner");
        _;
    }
    constructor (uint8 _buyerFee, uint8 _sellerFee,TransferProxy _transferProxy)  {
        buyerFeePermille = _buyerFee;
        sellerFeePermille = _sellerFee;
        transferProxy = _transferProxy;
        owner = msg.sender;
    }
    function buyerServiceFee() external view virtual returns (uint8) {
        return buyerFeePermille;
    }
    function sellerServiceFee() external view virtual returns (uint8) {
        return sellerFeePermille;
    }
    function getNonceQuantity(uint256 nonce) external view returns (uint256) {
        return users[nonce].supply;
    }
    function setBuyerServiceFee(uint8 _buyerFee) external onlyOwner returns (bool) {
        buyerFeePermille = _buyerFee;
        emit BuyerFee(buyerFeePermille);
        return true;
    }
    function setSellerServiceFee(uint8 _sellerFee) external onlyOwner returns (bool) {
        sellerFeePermille = _sellerFee;
        emit SellerFee(sellerFeePermille);
        return true;
    }
    function transferOwnership(address newOwner) external onlyOwner returns (bool) {
        require(newOwner != address(0), "Ownable : new owner is the zero address");
        emit OwnershipTransferred(owner , newOwner);
        owner  = newOwner;
        return true;
    }
    function getSigner(bytes32 hash, Sign memory sign) internal pure returns(address) {
        return ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)),sign.v,sign.r, sign.s);
    }
    function verifySellerSign(address seller, uint256 tokenId, uint amount , uint256 supply, address paymentAssetAddress, address assetAddres, Sign memory sign) internal pure {
        bytes32 hash = keccak256(abi.encodePacked(assetAddres,tokenId,paymentAssetAddress,amount,supply,sign.nonce));
        require(seller == getSigner(hash,sign), "seller sign verfication failed");

    }
    function verifyBuyerSign(address buyer , uint256 tokenId, uint256 amount , address paymentAddress , uint qty , Sign memory sign) internal pure {
        bytes32 hash = keccak256(abi.encodePacked(assetAddress , tokenId,paymentAddress,amount ,qty,sign.nonce));
        require(buyer == getSigner(hash,sign), "buyer sign verification failed");
    }
    function getFees(uint paymentAmt, BuyingAssetType buyingAssetType, address buyingAssetAddress , uint tokenId) internal view returns (Fee memory) {
        address tokenCreator;
        uint platformFee;
        uint royaltyFee;
        uint assetFee;
        uint royalityPermille;
        uint price = paymentAmt  * 1000 / (1000 + buyerFeePermille);
        uint buyerFee = paymentAmt - price;
        uint SellerFee = price * sellerFeePermille / 1000;
        platformFee = buyerFee + sellerFee;
        if (buyingAssetType == BuyingAssetType.ERC721) {
            royaltyPermille = ((IERC721(buyingAssetAddress).royaltyFee(tokenId)));
            tokenCreator = ((IERC721(buyingAssetAddress).getCreator(tokenId)));
        }
        if (buyingAssetType == BuyingAssetType.ERC1155) {
            royaltyPermille = ((IERC1155(buyingAssetAddress).royalty(tokenId)));
            tokenCreator = ((IERC1155(buyingAssetAddress).getCreator(tokenId)));
        }
        royalityFee = price  * royaltyPermille / 1000;
        assetFee = price - royaltyFee - sellerFee;
        return Fee(platformFee,assetFee,royaltyFee,price , tokenCreator);

    }

    function tradeAsset(Order calldata order , Fee memory fee, address buyer , address seller) internal virtual {
        if (order.nftType == BuyingAssetType.ERC721) {
            transferProxy.erc721safeTransferFrom(IERC721(order.nftAddress),seller , buyer, order.tokenId,order.qty, "Transfer Succesfull");
        }
        if (order.nftType ==BuyingAssetType.ERC1155){
            TransferProxy.erc1155safeTransferFrom(IERC1155(order.nftAddress),seller,buyer,order.tokenId.order.qty, "Transfer Succesfull");
        }
        if(fee.platformFee > 0) {
            transferProxy.erc20safeTransferFrom(IERC20(order.erc20Address), buyer, owner, fee.platformFee);
        }
        if(fee.royaltyFee > 0) {
            transferProxy.erc20safeTransferFrom(IERC20(order.erc20Address), buyer, fee.tokenCreator, fee.royaltyFee);
        }
        transferProxy.erc20safeTransferFrom(IERC20(order.erc20Address), buyer, seller, fee.assetFee);
    }

    function buyAsset(Order calldata order, uint256 supply , Sign calldata sign) external returns(bool) {
        require(!usedNonce[sign.nonce], "Nonce: Invalid nonce");
        if (order.nftType == BuyingAssetType.ERC721) {
            usedNonce[sign.nonce] =true;
        }
        else if (order.nftType == BuyingAssetType.ERC1155 ) {
            if (users[sign.nonce].initialize) {
                require(users[sign.nonce].nftAddress == order.nftAddress && users[sign.nonce].seller == order.seller && users[sign.nonce].tokenId == order.tokenId, "Nonce : Invalid Data");
                require(users[sign.nonce].supply >= order.qty, "Invalid Quantity");
                users[sign.nonce].supply -= order.qty;
                if (users[sign.nonce].supply == 0) {
                    usedNonce[sign.nonce] = ture;
                }
            }
        }
        Fee memory fee = getFees(order.amount,order.nftType, order.nftAddress,order.tokenId);
        require((fee.rice >= order.unitPrice *order.qty), "Paid invalid amount");
        verifySellerSign(order.seller , order.tokenId, order.unitPrice,supply, order.erc20Address, order.nftAddress, sign);
        address buyer = msg.sender;
        tradeAsset(order , fee ,buyer , order.seller);
        emit BuyAsset(order.seller , order.tokenId, order.qty,msg.sender);
        return true;
    }
    function executeBid(Order calldata  order, Sign calldata sign) external returns(bool) {
        require(!usedNonce[sign.nonce]);
        usedNonce[sign.nonce] = true;
        Fee memory fee = getFees(order.amount,order.nftType,order.nftAddress,order.tokenId);
        verifyBuyerSign(order.buyer, order.tokenId,order.amount,order.erc20Address,order.nftAddress,order.qty,sign);
        address seller  = msg.sender;
        tradeAsset(order , fee, order.buyer,seller);
        emit ExecuteBid(msg.sender,order.tokenId,order.qty,order.buyer);
        return true;
    }

}