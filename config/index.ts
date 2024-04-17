export const chainNames = ["avalanche", "avalancheFuji"] as const;
export type ChainName = (typeof chainNames)[number];

export const chainNameToId = {
  avalanche: 43114,
  avalancheFuji: 43113,
} as const;

export type ChainId = (typeof chainNameToId)[ChainName];

type AddressMap = {
  [key: string]: {
    [K in ChainName]: `0x${string}`;
  };
};

type Config<T> = {
  [key: string]: {
    [K in ChainName]: T;
  };
};

export const config: Config<bigint> = {
  slippage: { avalancheFuji: BigInt("10000"), avalanche: BigInt("200") },
  minimumNative: {
    avalancheFuji: BigInt("1000000000000000"),
    avalanche: BigInt("10000000000000000000"),
  },
  launchFeeUSDC: {
    avalancheFuji: BigInt("1000000"),
    avalanche: BigInt("250000000"),
  },
  minimumLockDuration: {
    avalancheFuji: BigInt("1"),
    avalanche: BigInt("90"),
  },
} as const;

export const addresses: AddressMap = {
  teamMultiSig: {
    avalancheFuji: "0xb2a30d5D43DE954b32FacefEa17561c51b7baE9B",
    avalanche: "0x6769DB4e3E94A63089f258B9500e0695586315bA",
  },
  vaporDexRouter: {
    avalancheFuji: "0x19C0FC4562A4b76F27f86c676eF5a7e38D12a20d",
    avalanche: "0x19C0FC4562A4b76F27f86c676eF5a7e38D12a20d",
  },
  vaporDexFactory: {
    avalancheFuji: "0xC009a670E2B02e21E7e75AE98e254F467f7ae257",
    avalanche: "0xC009a670E2B02e21E7e75AE98e254F467f7ae257",
  },
  stratosphereNFT: {
    avalancheFuji: "0x26b794235422e7c6f3ac6c717b10598C2a144203",
    avalanche: "0x08e287adCf9BF6773a87e1a278aa9042BEF44b60",
  },
  vaporDexAggregatorRouter: {
    avalancheFuji: "0x55477d8537ede381784b448876AfAa98aa450E63",
    avalanche: "0x55477d8537ede381784b448876AfAa98aa450E63",
  },
  vaporDexAggregatorAdapter: {
    avalancheFuji: "0x3F1aF4D92c91511A0BCe4B21bc256bF63bcab470",
    avalanche: "0x01e5C45cB25E30860c2Fb80369A9C27628911a2b",
  },
  usdc: {
    avalancheFuji: "0xeA42E3030ab1406a0b6aAd077Caa927673a2c302",
    avalanche: "0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E",
  },
  vape: {
    avalancheFuji: "0x3bD01B76BB969ef2D5103b5Ea84909AD8d345663",
    avalanche: "0x7bddaF6DbAB30224AA2116c4291521C7a60D5f55",
  },
  weth: {
    avalancheFuji: "0xd00ae08403B9bbb9124bB305C09058E32C39A48c",
    avalanche: "0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7",
  },
  sablier: {
    avalancheFuji: "0xebf7ed508a0Bb1c4e66b9E6F8C6a73342E7049ac",
    avalanche: "0xB24B65E015620455bB41deAAd4e1902f1Be9805f",
  },
  nonFungiblePositionManager: {
    avalancheFuji: "0x7a0A7C4273B25b3a71Daeaa387c7855081AC4E56",
    avalanche: "0xC967b23826DdAB00d9AAd3702CbF5261B7Ed9a3a",
  },
  create3Factory: {
    avalancheFuji: "0x8f3b1d04C01621553ee04A7B118844c356307f14",
    avalanche: "0x8f3b1d04C01621553ee04A7B118844c356307f14",
  },
} as const;

export const BURN_WALLET = "0x000000000000000000000000000000000000dEaD";
