const { upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const { getSettings} = require("./config.js");

const ExchangeV2 = artifacts.require('ExchangeV2');
const ExchangeMetaV2 = artifacts.require('ExchangeMetaV2');

module.exports = async function (deployer,network) {
    const {deploy_meta , deploy_non_meta} = getSettings(network);
    if (!!deploy_meta) {
        await updateExchange(ExchangeMetaV2, deployer);
    }
    if (!!deploy_non_meta) {
        await updateExchange(ExchangeV2, deployer);
    }
};
async function updateExchange(exchange , deployer) {
    const existing = await exchange.deployed();
    await upgradeProxy(existing.address ,exchange, { deployer });
}