import "dotenv/config";
import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-deploy";

const deployerKey = process.env.DEPLOYER_KEY || "";
const accounts = [deployerKey];

const config: HardhatUserConfig = {
  etherscan: {
    apiKey: {
      snowtrace: "snowtrace",
    },
    customChains: [
      {
        network: "snowtrace",
        chainId: 43114,
        urls: {
          apiURL:
            "https://api.routescan.io/v2/network/mainnet/evm/43114/etherscan",
          browserURL: "https://avalanche.routescan.io",
        },
      },
      {
        network: "snowtrace",
        chainId: 43113,
        urls: {
          apiURL:
            "https://api.routescan.io/v2/network/fuji/evm/43113/etherscan",
          browserURL: "https://cchain.explorer.avax-test.network",
        },
      },
    ],
  },
  namedAccounts: {
    deployer: {
      default: 0,
    },
  },
  solidity: {
    version: "0.8.22",
    settings: {
      evmVersion: "paris",
      optimizer: {
        enabled: true,
        runs: 1000000,
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
