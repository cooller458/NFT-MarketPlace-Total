const { upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const Locking = artifacts.require('Locking');

module.exports = async function (deployer) {
    const existing = await Locking.deployed();
    await upgradeProxy(existing.address, Locking, { deployer });
}