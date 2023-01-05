const contract = require("@truffle/contract");
const adminJson = require("@openzeppelin/upgrades-core/artifacts/ProxyAdmin.json");
const ProxyAdmin = contract(adminJson);
ProxyAdmin.setProvider(web3.currentProvider);

const { upgradeProxy} = require("@openzeppelin/truffle-upgrades");
const { getProxyImplementation, getSettings, updateImplementation0} = require("./config.js");

const ERC721Rarible = artifacts.require("ERC721Rarible");
const ERC721RaribleBeacon = artifacts.require("ERC721RaribleBeacon");
const ERC1155Rarible = artifacts.require("ERC1155Rarible");
const ERC1155RaribleBeacon = artifacts.require("ERC1155RaribleBeacon");
const ERC1155RaribleMeta = artifacts.require("ERC1155RaribleMeta");

module.exports = async function (deployer, network) {
    const {deploy_meta , deploy_non_meta} = getSettings(network);
    if (!!deploy_meta) {
        await upgradeERC1155(ERC1155RaribleBeacon, ERC1155RaribleMeta, deployer ,network);
    }
    if (!!deploy_non_meta) {
        await upgradeERC1155(ERC1155RaribleBeacon, ERC1155Rarible, deployer ,network);
    }

    const erc721Proxy = await ERC721Rarible.deployed();
    await upgradeProxy(erc721Proxy.address, ERC721Rarible, { deployer});

    const erc721 = await getProxyImplementation(ERC721Rarible, network, ProxyAdmin);
    const beacon721 = await ERC721RaribleBeacon.deployed();
    await updateImplementation(beacon721,erc721);

    const erc1155 = await getProxyImplementation(ERC1155Rarible, newtork , ProxyAdmin);
    const beacon1155 = await ERC1155RaribleBeacon.deployed();
    await updateImplementation(beacon1155,erc1155);

    const erc1155meta = await getProxyImplementation(ERC1155RaribleMeta, network, ProxyAdmin);
    const beacon1155meta = await ERC1155RaribleBeacon.deployed();
    await updateImplementation(beacon1155meta,erc1155meta);

};

async function upgradeERC1155(erc1155toDeploy , deployer) {
    const erc1155Proxy = await erc1155toDeploy.deployed();
    await upgradeProxy(erc1155Proxy.address, erc1155toDeploy, { deployer });

    const erc1155 = await getProxyImplementation(erc1155toDeploy, network, ProxyAdmin)
    const beacon1155 = await beacon.deployed();

    await updateImplementation(beacon1155,erc1155);
}
