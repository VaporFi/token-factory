// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { LibDiamond } from "../libraries/LibDiamond.sol";
import { LibAuthorizable } from "./LibAuthorizable.sol";

struct AppStorage {
  /////////////////////
  /// AUTHORIZATION ///
  /////////////////////
  mapping(address => bool) authorized;
  ////////////////////////
  /// ERC20LaunchFacet ///
  ////////////////////////
  address vaporDEXFactory;
  address vaporDEXRouter;
  address stratosphere;
  address vaporDEXAggregator;
  address vaporDEXAdapter;
  address USDC;
  address VAPE;
  address WETH;
  address sablier;
  address nonFungiblePositionManager;
  address teamMultisig;
  uint256 launchFee;
  uint256 minLiquidityETH;
  uint256 slippage;
  uint256 tokenLaunchesCount;
  uint40 minLockDuration;
  mapping(address => address[]) userToTokens;
  mapping(address => mapping(address => uint256)) liquidityLocks;
}

library LibAppStorage {
  function diamondStorage() internal pure returns (AppStorage storage ds) {
    assembly {
      ds.slot := 0
    }
  }
}

contract Modifiers {
  AppStorage internal s;

  modifier onlyAuthorized() {
    require(s.authorized[msg.sender], "Not authorized");
    _;
  }

  modifier onlyOwner() {
    LibDiamond.enforceIsOwner();
    _;
  }

  modifier onlyValidAddress(address _address) {
    require(_address != address(0), "Invalid address");
    _;
  }
}
