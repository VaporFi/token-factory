import { ethers, network } from "hardhat";
import { deployContract } from "../../utils/deployContract";
import { parseEther } from "ethers";
import { ChainName, addresses } from "../../config";

const chain = (network.name || "avalancheFuji") as ChainName;

async function deployERC20Token() {
  const [deployer] = await ethers.getSigners();
  await deployContract("ERC20Token", {
    args: [
      "WHYYYYYYYY!?",
      "WHYYY",
      parseEther("1000000000").toString(),
      addresses.stratosphereNFT[chain],
      deployer.address,
      Math.round(Date.now() / 1000),
      addresses.vaporDexAggregatorRouter[chain],
      addresses.vaporDexAggregatorAdapter[chain],
      deployer.address,
    ],
  });
}

deployERC20Token().catch((error) => {
  console.error(error);
  process.exit(1);
});
