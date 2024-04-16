import { network } from "hardhat";
import TokenFactoryDiamond from "../deployments/TokenFactoryDiamond.json";
import { deployContract } from "../utils/deployContract";
import { addOrReplaceFacets } from "../utils/diamond";
import getFacets from "../utils/getFacets";

async function main() {
  console.log("💎 Upgrading diamond");
  const diamondAddress =
    TokenFactoryDiamond[network.name as keyof typeof TokenFactoryDiamond]
      .address;

  // Deploy Facets
  const FacetNames = getFacets(["DiamondCutFacet", "DiamondLoupeFacet"]);

  const Facets = [];
  for (const name of FacetNames) {
    Facets.push(await deployContract(name));
  }

  // Do diamond cut
  await addOrReplaceFacets({ facets: Facets, diamondAddress });
  console.log("✅ Diamond upgraded");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
