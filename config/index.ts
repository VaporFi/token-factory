export const addresses: {
  [key: string]: {
    [chainId: number]: string;
  };
} = {
  teamMultiSig: {
    43_113: "0xCf00c1ac6D26d52054ec89bE6e093F2E270D61d9",
    43_114: "0x6769DB4e3E94A63089f258B9500e0695586315bA",
  },
  vaporDexRouter: {
    43_113: "0x19C0FC4562A4b76F27f86c676eF5a7e38D12a20d",
    43_114: "0x19C0FC4562A4b76F27f86c676eF5a7e38D12a20d",
  },
  stratosphereNFT: {
    43_113: "0x65eB37AeB1F2a9cE39556F80044607dD969b0336",
    43_114: "0x08e287adCf9BF6773a87e1a278aa9042BEF44b60",
  },
  vaporDexAggregatorRouter: {
    43_113: "0x55477d8537ede381784b448876AfAa98aa450E63",
    43_114: "0x55477d8537ede381784b448876AfAa98aa450E63",
  },
  vaporDexAggregatorAdapter: {
    43_113: "0x3F1aF4D92c91511A0BCe4B21bc256bF63bcab470",
    43_114: "0x01e5C45cB25E30860c2Fb80369A9C27628911a2b",
  },
  usdc: {
    43_113: "0xeA42E3030ab1406a0b6aAd077Caa927673a2c302",
    43_114: "0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E",
  },
  vape: {
    43_113: "0x3bD01B76BB969ef2D5103b5Ea84909AD8d345663",
    43_114: "0x7bddaF6DbAB30224AA2116c4291521C7a60D5f55",
  },
  sablier: {
    // note: THIS IS INCORRECT
    43_113: "0xB24B65E015620455bB41deAAd4e1902f1Be9805f",
    43_114: "0xB24B65E015620455bB41deAAd4e1902f1Be9805f",
  },
  nonFungiblePositionManager: {
    43_113: "0x7a0A7C4273B25b3a71Daeaa387c7855081AC4E56",
    43_114: "0xC967b23826DdAB00d9AAd3702CbF5261B7Ed9a3a",
  },
} as const;
