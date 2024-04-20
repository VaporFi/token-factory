import { task } from "hardhat/config";
import getContractDeployment from "../utils/getContractDeployment";
import { ChainName, addresses, config } from "../config";

task(
  "admin:set-stratosphere",
  "Set Stratosphere as the admin of the TokenFactoryDiamond"
).setAction(async (taskArgs, { ethers, network }) => {
  const { address, args } = await getContractDeployment(
    "TokenFactoryDiamond",
    network.name
  );
  const adminFacet = await ethers.getContractAt("AdminFacet", address);
  const stratosphereAddress =
    addresses.stratosphereNFT[network.name as ChainName];

  try {
    await adminFacet.setStratosphere(stratosphereAddress);
  } catch (err) {
    console.log(err);
    return;
  }
});

task("admin:set-slippage", "Set the slippage").setAction(
  async (taskArgs, { ethers, network }) => {
    const { address, args } = await getContractDeployment(
      "TokenFactoryDiamond",
      network.name
    );
    const adminFacet = await ethers.getContractAt("AdminFacet", address);

    try {
      // await adminFacet.setSlippage(config.slippage[network.name as ChainName]);
      const txData = adminFacet.interface.encodeFunctionData("setSlippage", [
        config.slippage[network.name as ChainName],
      ]);
      console.log("🚀 ~ txData:", txData);
    } catch (err) {
      console.log(err);
      return;
    }
  }
);
