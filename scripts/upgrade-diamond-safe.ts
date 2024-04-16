import Safe, { EthersAdapter } from "@safe-global/protocol-kit";
import { ethers, network } from "hardhat";
import TokenFactoryDiamond from "../deployments/TokenFactoryDiamond.json";
import { deployContract } from "../utils/deployContract";
import { addOrReplaceFacets } from "../utils/diamond";
import getFacets from "../utils/getFacets";
import { ChainName, addresses } from "../config";

const chain = (network.name || "avalancheFuji") as ChainName;

async function main() {
  console.log("💎 Upgrading diamond");
  const diamondAddress =
    TokenFactoryDiamond[network.name as keyof typeof TokenFactoryDiamond]
      .address;

  // Deploy Facets
  const FacetNames = getFacets(["DiamondCutFacet"]);

  const Facets = [];
  for (const name of FacetNames) {
    Facets.push(await deployContract(name));
  }

  // Create Safe Adapter
  const [deployer] = await ethers.getSigners();
  // @ts-expect-error mismatch types between Safe and Hardhat
  const ethAdapter = new EthersAdapter({ ethers, signerOrProvider: deployer });
  const safeSdk = await Safe.create({
    ethAdapter,
    safeAddress: addresses.teamMultiSig[chain],
  });

  // Do diamond cut
  console.log("💎 Adding facets");
  await addOrReplaceFacets({
    facets: Facets,
    diamondAddress,
    safe: safeSdk,
  });

  console.log("✅ Diamond upgraded");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
