pragma solidity 0.8.4;

import "@openzeppelin/conracts/utils/String.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeeplin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzepplin/contracts/token/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155Enumerable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155Metadata.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";


contract Name {
  uint256 newItemId = 1;
  address public owner;
  mapping (uint256=>bool) private usedNonce;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  struct Sign {
    uint8 v;
    bytes32 r;
    bytes32 s;
    uint256 nonce;
  }
  constructor (string memory tokenName, string memory tokenSymbol) ERC1155(tokenName, tokenSymbol) {
    owner = msg.sender;
  }

  modifier onlyOwner {
    require(owner == msg.sender, "Ownable : caller is not the owner");
    _;
  }

  function transferOwnership(address newOwner) external onlyOwner returns(bool) {
    require(newOwner != address(0) , "Ownable: new owner is the zero address");
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
    return true;
  }
  function verifySign(string memory tokenURI, address caller, Sign memory sign) internal view {
        bytes32 hash = keccak256(abi.encodePacked(this, caller, tokenURI, sign.nonce));
        require(owner == ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)), sign.v, sign.r, sign.s), "Owner sign verification failed");
    }

    function mint(string memory uri, uint256 supply, uint256 fee, Sign memory sign) external {
        require(!usedNonce[sign.nonce], "Nonce : Invalid Nonce");
        usedNonce[sign.nonce] = true;
        verifySign(uri, _msgSender(), sign);
        _mint(newItemId, supply, uri,fee);
        newItemId = newItemId + 1;
    }

    function setBaseURI(string memory _baseURI) external onlyOwner{
         _setTokenURIPrefix(_baseURI);
    }

    function burn(uint256 tokenId, uint256 supply) external {
        _burn(msg.sender, tokenId, supply);
    }

    function burnBatch( uint256[] memory tokenIds, uint256[] memory amounts) external {
        _burnBatch(msg.sender, tokenIds, amounts);
    }
  



}