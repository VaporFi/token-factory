import "dotenv/config";
import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

import "./tasks/admin";
import "./tasks/verify";
import "./tasks/erc20token";

const deployerKey = process.env.DEPLOYER_KEY || "";
const accounts = deployerKey ? [deployerKey] : [];

const config: HardhatUserConfig = {
  etherscan: {
    apiKey: {
      snowtrace: "snowtrace",
      snowtraceFuji: "snowtraceFuji",
    },
    customChains: [
      {
        network: "snowtrace",
        chainId: 43114,
        urls: {
          apiURL:
            "https://api.routescan.io/v2/network/mainnet/evm/43114/etherscan",
          browserURL: "https://snowtrace.dev/",
        },
      },
      {
        network: "snowtraceFuji",
        chainId: 43113,
        urls: {
          apiURL:
            "https://api.routescan.io/v2/network/testnet/evm/43113/etherscan",
          browserURL: "https://testnet.snowtrace.io/",
        },
      },
    ],
  },
  solidity: {
    version: "0.8.25",
    settings: {
      evmVersion: "paris",
      optimizer: {
        enabled: true,
        runs: 1_000_000,
      },
    },
  },
  networks: {
    avalanche: {
      accounts,
      chainId: 43114,
      url: "https://api.avax.network/ext/bc/C/rpc",
    },
    avalancheFuji: {
      accounts,
      chainId: 43113,
      url: "https://api.avax-test.network/ext/bc/C/rpc",
    },
  },
};

export default config;
