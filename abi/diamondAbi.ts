export const diamondAbi = [
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "owner",
        "type": "address"
      },
      {
        "internalType": "address",
        "name": "sender",
        "type": "address"
      }
    ],
    "name": "LibDiamond__OnlyOwner",
    "type": "error"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "address",
        "name": "oldOwner",
        "type": "address"
      },
      {
        "indexed": true,
        "internalType": "address",
        "name": "newOwner",
        "type": "address"
      }
    ],
    "name": "OwnershipTransferred",
    "type": "event"
  },
  {
    "inputs": [],
    "name": "owner",
    "outputs": [
      {
        "internalType": "address",
        "name": "owner_",
        "type": "address"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "_owner",
        "type": "address"
      }
    ],
    "name": "transferOwnership",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "AdminFacet__Invalid",
    "type": "error"
  },
  {
    "inputs": [],
    "name": "AdminFacet__ZeroAddress",
    "type": "error"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": false,
        "internalType": "address",
        "name": "_to",
        "type": "address"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "_amount",
        "type": "uint256"
      }
    ],
    "name": "AccumulatedFeesWithdrawn",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "_launchFee",
        "type": "uint256"
      }
    ],
    "name": "LaunchFeeUpdated",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "_liquidity",
        "type": "uint256"
      }
    ],
    "name": "MinimumLiquidityETHUpdated",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": false,
        "internalType": "uint40",
        "name": "_lockDuration",
        "type": "uint40"
      }
    ],
    "name": "MinimumLockDurationUpdated",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "_slippage",
        "type": "uint256"
      }
    ],
    "name": "SlippageUpdated",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": false,
        "internalType": "address",
        "name": "_vaporDexAdapter",
        "type": "address"
      }
    ],
    "name": "VaporDEXAdapterUpdated",
    "type": "event"
  },
  {
    "inputs": [],
    "name": "getLaunchFee",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "_token",
        "type": "address"
      }
    ],
    "name": "getTokenDetails",
    "outputs": [
      {
        "internalType": "address",
        "name": "deployer",
        "type": "address"
      },
      {
        "internalType": "address",
        "name": "tokenAddress",
        "type": "address"
      },
      {
        "internalType": "address",
        "name": "liquidityPool",
        "type": "address"
      },
      {
        "internalType": "uint256",
        "name": "tradingStartsAt",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "streamId",
        "type": "uint256"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "_owner",
        "type": "address"
      }
    ],
    "name": "getTokenLaunches",
    "outputs": [
      {
        "internalType": "address[]",
        "name": "",
        "type": "address[]"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "getVaporDEXAdapter",
    "outputs": [
      {
        "internalType": "address",
        "name": "",
        "type": "address"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "_launchFee",
        "type": "uint256"
      }
    ],
    "name": "setLaunchFee",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint40",
        "name": "_lockDuration",
        "type": "uint40"
      }
    ],
    "name": "setMinLockDuration",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "_liquidity",
        "type": "uint256"
      }
    ],
    "name": "setMinimumLiquidityETH",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "_slippage",
        "type": "uint256"
      }
    ],
    "name": "setSlippage",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "_vaporDexAdapter",
        "type": "address"
      }
    ],
    "name": "setVaporDEXAdapter",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "_to",
        "type": "address"
      }
    ],
    "name": "withdrawFee",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "LaunchERC20Facet__InsufficientBalance",
    "type": "error"
  },
  {
    "inputs": [],
    "name": "LaunchERC20Facet__MinimumLockDuration",
    "type": "error"
  },
  {
    "inputs": [],
    "name": "LaunchERC20Facet__NotEnoughLiquidity",
    "type": "error"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "_from",
        "type": "address"
      }
    ],
    "name": "LaunchERC20Facet__TranferFailed",
    "type": "error"
  },
  {
    "inputs": [],
    "name": "LaunchERC20Facet__WrongLaunchArguments",
    "type": "error"
  },
  {
    "inputs": [],
    "name": "LaunchERC20Facet__ZeroAddress",
    "type": "error"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "address",
        "name": "pair",
        "type": "address"
      },
      {
        "indexed": true,
        "internalType": "address",
        "name": "_burner",
        "type": "address"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "_amount",
        "type": "uint256"
      }
    ],
    "name": "LiquidityBurned",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "address",
        "name": "_pairAddress",
        "type": "address"
      },
      {
        "indexed": true,
        "internalType": "address",
        "name": "_receiver",
        "type": "address"
      }
    ],
    "name": "LiquidityTokensUnlocked",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "address",
        "name": "_pairAddress",
        "type": "address"
      },
      {
        "indexed": true,
        "internalType": "address",
        "name": "_to",
        "type": "address"
      }
    ],
    "name": "LiquidityTransferred",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "uint256",
        "name": "_streamId",
        "type": "uint256"
      },
      {
        "indexed": true,
        "internalType": "address",
        "name": "_sender",
        "type": "address"
      },
      {
        "indexed": true,
        "internalType": "address",
        "name": "_pair",
        "type": "address"
      }
    ],
    "name": "StreamCreated",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "address",
        "name": "_tokenAddress",
        "type": "address"
      },
      {
        "indexed": true,
        "internalType": "address",
        "name": "_creatorAddress",
        "type": "address"
      },
      {
        "indexed": true,
        "internalType": "uint256",
        "name": "_streamId",
        "type": "uint256"
      }
    ],
    "name": "TokenLaunched",
    "type": "event"
  },
  {
    "inputs": [
      {
        "internalType": "string",
        "name": "_name",
        "type": "string"
      },
      {
        "internalType": "string",
        "name": "_symbol",
        "type": "string"
      },
      {
        "internalType": "uint256",
        "name": "_totalSupply",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "_tradingStartsAt",
        "type": "uint256"
      },
      {
        "internalType": "uint40",
        "name": "lockDuration",
        "type": "uint40"
      },
      {
        "internalType": "bool",
        "name": "_burnLiquidity",
        "type": "bool"
      }
    ],
    "name": "launchERC20",
    "outputs": [
      {
        "internalType": "address",
        "name": "_pair",
        "type": "address"
      },
      {
        "internalType": "address",
        "name": "_tokenAddress",
        "type": "address"
      },
      {
        "internalType": "uint256",
        "name": "streamId",
        "type": "uint256"
      }
    ],
    "stateMutability": "payable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "_address",
        "type": "address"
      }
    ],
    "name": "authorize",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "_address",
        "type": "address"
      }
    ],
    "name": "authorized",
    "outputs": [
      {
        "internalType": "bool",
        "name": "",
        "type": "bool"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "_address",
        "type": "address"
      }
    ],
    "name": "unAuthorize",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "LiquidityLockFacet__LiquidityLockedOrDepleted",
    "type": "error"
  },
  {
    "inputs": [],
    "name": "LiquidityLockFacet__Unauthorized",
    "type": "error"
  },
  {
    "inputs": [],
    "name": "LiquidityLockFacet__ZeroAddress",
    "type": "error"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": false,
        "internalType": "address",
        "name": "_tokenAddress",
        "type": "address"
      },
      {
        "indexed": false,
        "internalType": "address",
        "name": "_receiver",
        "type": "address"
      }
    ],
    "name": "LiquidityTokensUnlocked",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": false,
        "internalType": "address",
        "name": "_tokenAddress",
        "type": "address"
      },
      {
        "indexed": false,
        "internalType": "address",
        "name": "_to",
        "type": "address"
      }
    ],
    "name": "LiquidityTransferred",
    "type": "event"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "_tokenAddress",
        "type": "address"
      },
      {
        "internalType": "address",
        "name": "_to",
        "type": "address"
      }
    ],
    "name": "transferLock",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "_tokenAddress",
        "type": "address"
      },
      {
        "internalType": "address",
        "name": "_receiver",
        "type": "address"
      }
    ],
    "name": "unlockLiquidityTokens",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  }
] as const;