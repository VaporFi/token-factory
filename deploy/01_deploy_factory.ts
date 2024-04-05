import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { addresses, config } from "../config";
import { TokenFactory } from "../typechain-types/index";

const func: DeployFunction = async function ({
  getNamedAccounts,
  deployments,
  network,
}: HardhatRuntimeEnvironment) {
  const chainId = network.config.chainId;

  if (!chainId) {
    throw new Error("ChainId not found");
  }
  const args: TokenFactory.DeployArgsStruct = {
    owner: addresses.teamMultiSig[chainId],
    routerAddress: addresses.vaporDexRouter[chainId],
    stratosphereAddress: addresses.stratosphereNFT[chainId],
    vaporDexAggregator: addresses.vaporDexAggregatorRouter[chainId],
    vaporDexAdapter: addresses.vaporDexAggregatorAdapter[chainId],
    usdc: addresses.usdc[chainId],
    vape: addresses.vape[chainId],
    launchFee: config.launchFeeUSDC[chainId],
    minLiquidityETH: config.minimumNative[chainId],
    minLockDuration: config.minimumLockDuration[chainId],
    sablier: addresses.sablier[chainId],
    nonFungiblePositionManager: addresses.nonFungiblePositionManager[chainId],
    teamMultisig: addresses.teamMultiSig[chainId],
    slippage: config.slippage[chainId],
  };

  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  await deploy("TokenFactory", {
    from: deployer,
    args: [args],
    log: true,
  });
};

export default func;

func.tags = ["TokenFactory"];
