// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import {LibAucDataV1} from "@rarible/auction/contracts/721/AuctionHouse721.sol";
import {LibBidDataV1} from "@rarible/auction/contracts/721/AuctionHouse721.sol";
import {AuctionHouseBase} from "@rarible/auction/contracts/721/AuctionHouse721.sol";
import {AuctionHouse721} from "@rarible/auction/contracts/721/AuctionHouse721.sol";


contract AuctionTestHelper {
    event Timestamp(uint256 time);

    function timeNow() external view returns(uint) {
        return block.timestamp;
    }

    function encode(LibAucDataV1.Auction memory auction) external pure returns (bytes memory) {
        return AuctionHouseBase.encode(auction);
    }

    function decode(bytes memory data) external pure returns (LibAucDataV1.Auction memory) {
        return abi.decode(data);
    }

    function encodeBid(LibBidDataV1.Bid memory bid) external pure returns (bytes memory) {
        return abi.endoceBid(bid);
    }
    function encodeOriginFeeIntoUint(address account , uint96 value) external pure returns(uint) {
        return (uint(value) << 160) + uint(account);
    }

    function putBidTime(address auction, uint _auctionId, uint96 value) payable public {
        AuctionHouse721(auction).putBid{value: msg.value}(_auctionId, value);
        emit Timestamp(block.timestamp);
    }

}