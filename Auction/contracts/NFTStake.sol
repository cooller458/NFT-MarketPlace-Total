// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract BalanceNFTStake is ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Interfaces for ERC20 and ERC721
    IERC20 public rewardsToken;
    IERC721 public nftCollection;

    // constructor function to set the rewards token and NFT collection addreesses
    constructor(address _nftCollection, IERC20 _rewardsToken){
        nftCollection = _nftCollection;
        rewardsToken = _rewardsToken;
    }
    struct StakedToken {
        address staker;
        uint256 tokenId;

    }

    struct Staker {
        // amount of tokens staked by the staker
        uint256 amountStaked;
        
        //Staked token ids

        StakedToken[] stakedTokens;

        //Last time of the rewards were calculated for this user
        uint256 timeOfLastUpdate;

        //Calculated,but uncleimed reward for the user. the reward are calculated from the each time the user staked writes to the smart contracts
        uint256 unclaimedRewards;
    }

    // Rewards per hour per token deposited in wei
    uint256 private rewardsPerHour= 100000;

    //Mapping of user address to staker info
    mapping(address => Staker) public stakers;

    //Mapping of token id to staker , made for the sc  to remember who to send the rewards to
    mapping(uint256 => address) public stakerAddress;

    function stake(uint256 _tokenId) public nonReentrant {
        if (stakers[msg.sender].amountStaked > 0) {
            uint256 rewards = calculateRewards(msg.sender);
            stakers[msg.sender].unclaimedRewards += rewards;
        }

        require(nftCollection.ownerOf(_tokenId) == msg.sender, "You do not own this token");
        nftCollection.transferFrom(msg.sender, address(this), _tokenId);
        StakedToken memory stakedToken = StakedToken(msg.sender, _tokenId);
        stakers[msg.sender].stakedTokens.push(stakedToken);
        stakers[msg.sender].amountStaked ++;
        stakerAddress[_tokenId] = msg.sender;
        stakers[msg.sender].timeOfLastUpdate = block.timestamp;
    }
    function withdraw(uint256 _tokenId) public nonReentrant {
        require(stakers[msgs.sender].amountStaked > 0, "You do not have any tokens staked");
        require(stakerAddress[_tokenId] == msg.sender, "You do not own this token");
        uint256 rewards = calculateRewards(msg.sender);
        stakers[msg.sender].unclaimedRewards += rewards;

        uint256 index = 0;
        for (uint256 i = 0; i < stakers[msg.sender].stakedTokens.length; i++) {
            if (
                stakers[msg.sender].stakedTokens[i].tokenId == _tokenId 
                && 
                stakers[msg.sender].stakedTokens[i].staker != address(0)
            ) {
                index = i;
                break;
            }
        }

        function calculateRewards(address _staker) public view returns (uint256) {
            uint256 timeSinceLastUpdate = block.timestamp - stakers[_staker].timeOfLastUpdate;
            uint256 rewards = (timeSinceLastUpdate * rewardsPerHour * stakers[_staker].amountStaked) / 3600;
            return rewards;
        }
    }
}