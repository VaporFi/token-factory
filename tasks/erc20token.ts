import { task } from "hardhat/config";
import getContractDeployment from "../utils/getContractDeployment";
import { ChainName, addresses, config } from "../config";

task("erc20token:set-lp", "Set LP address")
  .addParam("tokenAddress", "Address of the token")
  .addParam("lpAddress", "Address of the LP")
  .setAction(async ({ tokenAddress, lpAddress }, { ethers, network }) => {
    const { address, args } = await getContractDeployment(
      "ERC20Token",
      network.name
    );
    const token = await ethers.getContractAt("ERC20Token", tokenAddress);

    try {
      await token.setLiquidityPool(lpAddress);
    } catch (err) {
      console.log(err);
      return;
    }
  });
