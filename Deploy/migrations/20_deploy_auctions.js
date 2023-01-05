const {deployProxy} = require('@openzeppelin/truffle-upgrades');

const AuctionHouse721 = artifacts.require('AuctionHouse721');
const AuctionHouse1155 = artifacts.require('AuctionHouse1155');
const Wrapper = artifacts.require('Wrapper');

const RoyalitiesRegistry = artifacts.require('RoyaltiesRegistry');
const ERC20TransferProxy = artifacts.require('ERC20TransferProxy');
const TransferProxy = artifacts.require('TransferProxy');

const { getSettings} = require("./config.js");

module.exports = async function (deployer, network) {
    const { communityWallet} = getSettings(network);
    const ERC20TransferProxy = (await ERC20TransferProxy.deployed()).address;
    const RoyalitiesRegistry = (await RoyalitiesRegistry.deployed()).address;

    const auctionHouse721 = await deployProxy(AuctionHouse721, [communityWallet , RoyalitiesRegistry , transferProxy , ERC20TransferProxy, 0,100], 
        { deployer, initializer: 'initialize' });
    console.log(`deployed auctionHouse721 at ${auctionHouse721.address}`);

    const auctionHouse1155 = await deployProxy(AuctionHouse1155, [communityWallet , RoyalitiesRegistry , transferProxy , ERC20TransferProxy, 0,100],
        { deployer, initializer: 'initialize' });
    console.log(`deployed auctionHouse1155 at ${auctionHouse1155.address}`);
    
    const TransferProxyContract = await TransferProxy.deployed();

    await TransferProxyContract.addOperator(auctionHouse721.address);
    await TransferProxyContract.addOperator(auctionHouse1155.address);


    const ERC20TransferProxyContract = await ERC20TransferProxy.deployed();

    await ERC20TransferProxyContract.addOperator(auctionHouse721.address);
    await ERC20TransferProxyContract.addOperator(auctionHouse1155.address);

    await deployer.deploy(Wrapper , auctionHouse721.address);
    const wrapper = await Wrapper.deployed();
    console.log(`deployed wrapper at ${wrapper.address}`);
}