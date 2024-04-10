// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import {LibAuthorizable} from "./LibAuthorizable.sol";

struct TokenLaunch {
    string name;
    string symbol;
    uint256 tradingStartsAt;
    uint256 streamId;
    address tokenAddress;
    address pairAddress;
    address creatorAddress;
    bool isLiquidityBurned;
}

struct AppStorage {
    /////////////////////
    /// AUTHORIZATION ///
    /////////////////////
    mapping(address => bool) authorized;
    ////////////////////////
    /// ERC20LaunchFacet ///
    ////////////////////////
    address VaporDEXFactory;
    address VaporDEXRouter;
    address Stratosphere;
    address VaporDEXAggregator;
    address VaporDEXAdapter;
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
    mapping(uint256 => TokenLaunch) tokenLaunches;
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
