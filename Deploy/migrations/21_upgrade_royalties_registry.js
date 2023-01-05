const {upgradeProxy} = require('@openzeppelin/truffle-upgrades');

const RoyalitiesRegistry = artifacts.require('RoyaltiesRegistry');

module.exports = async function (deployer, network) {
    const existing = await RoyalitiesRegistry.deployed();
    await upgradeProxy(existing.address, RoyalitiesRegistry, { deployer });
};



