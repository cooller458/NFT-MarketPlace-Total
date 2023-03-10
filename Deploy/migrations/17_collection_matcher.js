const assetMatcherCollection = artifacts.require('AssetMatcherCollection');
const ExchangeV2 = artifacts.require('ExchangeV2');
const ExchangeMetaV2 = artifacts.require('ExchangeMetaV2');

const {id, getSettings} = require("./config.js");

module.exporst = async function (deployer, network) {
    await deployer.deploy(AssetMatcherCollection, {gas: 1500000});
    const matcher = await AssetMatcherCollection.deployed();
    console.log("asset matcher for collections deployed at : ", matcher.address);

    const settings = getSettings(network);
    if (!!settings.deploy_meta) {
        const exchangeV2 = await ExchangeMetaV2.deployed();
        await exchangeV2.setAssetMatcher(id.CRYPTO_PUNKS, matcher.address);
    }

    if (!!settings.deploy_non_meta) {
        const exchangeV2 = await ExchangeV2.deployed();
        await exchangeV2.setAssetMatcher(id("Collection"), matcher.address);
    }
}

