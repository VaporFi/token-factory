import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { addresses } from "../config";
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
    _owner: addresses.teamMultiSig[chainId],
    _routerAddress: addresses.vaporDexRouter[chainId],
    _stratosphereAddress: addresses.stratosphereNFT[chainId],
    _vaporDexAggregator: addresses.vaporDexAggregatorRouter[chainId],
    _vaporDexAdapter: addresses.vaporDexAggregatorAdapter[chainId],
    _usdc: addresses.usdc[chainId],
    _vape: addresses.vape[chainId],
    _launchFee: launchFee,
    _minLiquidityETH: BigInt(100000000),
    _minLockDuration: 2,
    _sablier: addresses.sablier[chainId],
    _nonFungiblePositionManager: addresses.nonFungiblePositionManager[chainId],
    _teamMultisig: addresses.teamMultiSig[chainId],
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
