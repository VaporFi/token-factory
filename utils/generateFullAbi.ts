import fs from "fs";
import path from "path";
import { artifacts } from "hardhat";
import type { AbiItemType } from "abitype";

async function generateFullAbi(): Promise<AbiItemType[]> {
  const excludedFacets: string[] = ["DiamondCutFacet", "DiamondLoupeFacet"];
  const facetsPath = path.join(__dirname, "../artifacts/contracts/facets");
  const facets: string[] = fs
    .readdirSync(facetsPath)
    .map((file) => file.replace(path.extname(file), ""));
  const abis: AbiItemType[] = [];

  for (const facet of facets) {
    if (excludedFacets.includes(facet)) {
      continue;
    }
    const abi = (await artifacts.readArtifact(facet)).abi;
    abis.push(...abi);
  }

  const uniqueAbis: AbiItemType[] = Array.from(
    new Set(abis.map((item) => JSON.stringify(item)))
  ).map((item) => JSON.parse(item));
  const dir = path.join(__dirname, "../abi");

  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir);
  }

  fs.writeFileSync(
    path.join(dir, "diamondAbi.ts"),
    `export const diamondAbi = ${JSON.stringify(uniqueAbis, null, 2)} as const;`
  );

  return uniqueAbis;
}

generateFullAbi().then(() => process.exit(0));
