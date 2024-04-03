import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { addresses, config } from "../config";
import { MemeFactory } from "../typechain-types/index";
const launchFee = "250000000";

const func: DeployFunction = async function ({
  getNamedAccounts,
  deployments,
  network,
}: HardhatRuntimeEnvironment) {
  const chainId = network.config.chainId;

  if (!chainId) {
    throw new Error("ChainId not found");
  }
  const args: MemeFactory.DeployArgsStruct = {
    owner: addresses.teamMultiSig[chainId],
    routerAddress: addresses.vaporDexRouter[chainId],
    stratosphereAddress: addresses.stratosphereNFT[chainId],
    vaporDexAggregator: addresses.vaporDexAggregatorRouter[chainId],
    vaporDexAdapter: addresses.vaporDexAggregatorAdapter[chainId],
    usdc: addresses.usdc[chainId],
    vape: addresses.vape[chainId],
    launchFee: launchFee,
    minLiquidityETH: BigInt(100000000),
    minLockDuration: 2,
    sablier: addresses.sablier[chainId],
    nonFungiblePositionManager: addresses.nonFungiblePositionManager[chainId],
    teamMultisig: addresses.teamMultiSig[chainId],
    slippage: config.slippage[chainId],
  };

  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  await deploy("MemeFactory", {
    from: deployer,
    args: [args],
    log: true,
  });
};
export default func;
