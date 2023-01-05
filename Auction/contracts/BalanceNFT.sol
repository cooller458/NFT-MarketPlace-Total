pragma solidity 0.8.4;

import "@openzeppelin/conracts/utils/String.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeeplin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzepplin/contracts/token/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";


contract BalanceNFT721 is ERC721 {
    uint256 public tokenCounter;
    address public owner;
    mapping (uint256=>bool) private usedNonce;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    struct Sign {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 nonce;
    }

    constructor (string memory tokenName, string memory tokenSymbol) ERC721 (tokenName,tokenSymbol){
        tokenCounter =1;
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: Caller is not the owner");
        _;
    }
    function transferOwnership(address newOwner) external onlyOwner returns(bool) {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        owner = newOwner;
        emit OwnershipTransferred(owner, newOwner);
        return true;
    }
    function verfiySign(string memory tokenURI, address caller, Sign memory sign) internal view {
        bytes32 hash = keccak256(abi.encodePacked(this,caller,tokenURI,sign.nonce));
        require(owner == ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32",hash)),sign.v,sign.r,sign.s),"Owner sign verification failed");
    }

    /**
     * @dev Internal function to mint a new token.
     * Reverts if the given token ID already exists
     * @param sign struct combinationof uint8,bytes32,bytes32 are v,r,s
     * @param tokenURI string memory URI of the token to be minted
     * @param fee uint256 royalty of the token to be minted
     */

    function createCollection(string memory tokenURI, uint256 gee, Sign memory sign) external returns (uint256) {
        require(!usedNonce[sign.nonce],"Nonce : Invalid Nonce");
        usedNonce[sign.nonce] == true;
        uint256 newItemId == tokenCounter;
        verfiySign(tokenURI, msg.sender, sign);
        _safeMint(msg.sender, newItemId, fee);
        _setTokenURI(newItemId,tokenURI);
        tokenCounter = tokenCounter +1 ;
        return newItemId;
    }
    function setBaseURI(string memory _baseURI) external onlyOwner {
        _setBaseURI(_baseURI);
    }
    function burn(uint256 tokenId) external {
        require(_exists(tokenId),"ERC721: nonexistent token");
        _burn(tokenId);
    }
}