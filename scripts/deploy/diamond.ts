import { BaseContract, Contract, encodeBytes32String } from "ethers";
import { ethers, network } from "hardhat";
import { addFacets } from "../../utils/diamond";
import { deployContract } from "../../utils/deployContract";
import { DiamondInit } from "../../typechain-types";
import getFacets from "../../utils/getFacets";
import { addresses, chainNameToId, config } from "../../config";
import type { ChainName } from "../../config";

const chain = (network.name || "avalancheFuji") as ChainName;

/// @dev IMPORTANT: Order matters here.
export const defaultArgs: DiamondInit.DeployArgsStruct = {
  routerAddress: addresses.vaporDexRouter[chain],
  factoryAddress: addresses.vaporDexFactory[chain],
  stratosphereAddress: addresses.stratosphereNFT[chain],
  vaporDexAggregator: addresses.vaporDexAggregatorRouter[chain],
  vaporDexAdapter: addresses.vaporDexAggregatorAdapter[chain],
  usdc: addresses.usdc[chain],
  vape: addresses.vape[chain],
  weth: addresses.weth[chain],
  launchFee: config.launchFeeUSDC[chain],
  minLiquidityETH: config.minimumNative[chain],
  minLockDuration: config.minimumLockDuration[chain],
  sablier: addresses.sablier[chain],
  nonFungiblePositionManager: addresses.nonFungiblePositionManager[chain],
  teamMultisig: addresses.teamMultiSig[chain],
  slippage: config.slippage[chain],
};

export const FacetNames = getFacets();

export async function deployDiamond(
  args: DiamondInit.DeployArgsStruct = defaultArgs
) {
  const [deployer] = await ethers.getSigners();
  // Deploy DiamondCutFacet
  const diamondCutFacet = await deployContract("DiamondCutFacet");

  // Deploy Diamond
  const diamond = await deployContract("TokenFactoryDiamond", {
    args: [deployer.address, await diamondCutFacet.getAddress()],
    log: true,
    // skipIfAlreadyDeployed: true,
    useCreate3Factory: true,
    salt: encodeBytes32String("VaporFi_TokenFactoryDiamond"),
  });
  const diamondAddress = await diamond.getAddress();

  // Deploy DiamondInit
  const diamondInit = await deployContract("DiamondInit");
  const diamondInitAddress = await diamondInit.getAddress();

  // Deploy Facets
  const facets: BaseContract[] = [];
  const facetsByName = {} as {
    [K in (typeof FacetNames)[number]]: BaseContract;
  };
  for (const FacetName of FacetNames) {
    const facet = (await deployContract(FacetName)) as any;

    facets.push(facet);
    facetsByName[FacetName] = facet;
  }

  // Add facets to diamond
  const functionCall = diamondInit.interface.encodeFunctionData("init", [
    Object.values(args),
  ]);

  await addFacets(facets, diamondAddress, diamondInitAddress, functionCall);

  // Transfer ownership to multisig
  const ownershipFacet = await ethers.getContractAt(
    "OwnershipFacet",
    diamondAddress
  );
  await ownershipFacet.transferOwnership(addresses.teamMultiSig[chain]);

  return diamond;
}
