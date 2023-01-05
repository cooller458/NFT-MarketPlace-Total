const { deployProxy} = require('@openzeppelin/truffle-upgrades');

const RoyaltiesRegistry = artifacts.require('RoyaltiesRegistry');

module.exports = async function (deployer) {
    const royaltiesRegistry = await deployProxy(RoyaltiesRegistry, [], {deployer, initializer: 'initialize'});
    console.log('RoyaltiesRegistry deployed to:', royaltiesRegistry.address);
}