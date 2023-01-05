import { balanceNFT } from "../contracts/BalanceNFT.sol";
import { deployContract } from 'ethereum-waffle';
import { ethers } from 'hardhat';


export async function deployBalanceNFT() {
  const [deployer] = await ethers.getSigners();
  const balanceNFT = await deployContract(deployer, balanceNFT);
  return balanceNFT;
}