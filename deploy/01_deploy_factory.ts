import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { addresses } from "../config";
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

  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  await deploy("MemeFactory", {
    from: deployer,
    args: [
      addresses.teamMultiSig[chainId], //owner
      addresses.vaporDexRouter[chainId], //router
      addresses.stratosphereNFT[chainId], //strat
      addresses.vaporDexAggregatorRouter[chainId], //aggregator
      addresses.vaporDexAggregatorAdapter[chainId], //adapter
      addresses.teamMultiSig[chainId], //multisig
      addresses.usdc[chainId], //usdc
      launchFee, // launch fee
      //sablier
    ],
    log: true,
  });
};
export default func;
