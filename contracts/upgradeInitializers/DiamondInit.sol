// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/******************************************************************************\
* Author: Nick Mudge <nick@perfectabstractions.com> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
*
* Implementation of a diamond.
/******************************************************************************/

import { IERC165 } from "@openzeppelin/contracts/interfaces/IERC165.sol";
import { LibDiamond } from "../libraries/LibDiamond.sol";
import { IDiamondLoupe } from "../interfaces/IDiamondLoupe.sol";
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";
import { IERC173 } from "../interfaces/IERC173.sol";
import { AppStorage } from "../libraries/LibAppStorage.sol";

error DiamondInit__WrongDeploymentArguments();

// It is expected that this contract is customized if you want to deploy your diamond
// with data from a deployment script. Use the init function to initialize state variables
// of your diamond. Add parameters to the init funciton if you need to.

// Adding parameters to the `init` or other functions you add here can make a single deployed
// DiamondInit contract reusable accross upgrades, and can be used for multiple diamonds.

contract DiamondInit {
  AppStorage s;
  /**
   * @dev TokenFactory constructor initializes the contract with required parameters.
   * @param routerAddress Address of the VaporDEXRouter contract.
   * @param factoryAddress Address of the VaporDEXFactory contract.
   * @param stratosphereAddress Address of the Stratosphere contract.
   * @param vaporDexAggregator Address of the VaporDEX aggregator.
   * @param vaporDexAdapter Address of the VaporDEX adapter.
   * @param usdc Address of the USDC token.
   * @param vape Address of the VAPE token.
   * @param weth Address of the WETH token.
   * @param launchFee Launch fee in USDC.
   * @param minLiquidityETH Minimum liquidity in ETH.
   * @param minLockDuration Minimum lock duration in seconds.
   * @param sablier Address of the Sablier contract.
   * @param nonFungiblePositionManager Uni v3 NFT Position Manager
   * @param teamMultisig Multisig address
   * @param slippage
   */
  struct DeployArgs {
    address routerAddress;
    address factoryAddress;
    address stratosphereAddress;
    address vaporDexAggregator;
    address vaporDexAdapter;
    address usdc;
    address vape;
    address weth;
    uint256 launchFee;
    uint256 minLiquidityETH;
    uint40 minLockDuration;
    address sablier;
    address nonFungiblePositionManager;
    address teamMultisig;
    uint256 slippage;
  }

  // You can add parameters to this function in order to pass in
  // data to set your own state variables
  function init(DeployArgs memory _args) external {
    // adding ERC165 data
    LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
    ds.supportedInterfaces[type(IERC165).interfaceId] = true;
    ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
    ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
    ds.supportedInterfaces[type(IERC173).interfaceId] = true;

    // add your own state variables
    // EIP-2535 specifies that the `diamondCut` function takes two optional
    // arguments: address _init and bytes calldata _calldata
    // These arguments are used to execute an arbitrary function using delegatecall
    // in order to set state variables in the diamond during deployment or an upgrade
    // More info here: https://eips.ethereum.org/EIPS/eip-2535#diamond-interface

    // Check for valid constructor arguments
    if (
      _args.routerAddress == address(0) ||
      _args.stratosphereAddress == address(0) ||
      _args.vaporDexAggregator == address(0) ||
      _args.vaporDexAdapter == address(0) ||
      _args.usdc == address(0) ||
      _args.launchFee == 0 ||
      _args.sablier == address(0) ||
      _args.minLiquidityETH == 0 ||
      _args.minLockDuration == 0 ||
      _args.weth == address(0) ||
      _args.nonFungiblePositionManager == address(0) ||
      _args.teamMultisig == address(0)
    ) {
      revert DiamondInit__WrongDeploymentArguments();
    }

    s.vaporDEXRouter = _args.routerAddress;
    s.vaporDEXFactory = _args.factoryAddress;
    s.stratosphere = _args.stratosphereAddress;
    s.vaporDEXAggregator = _args.vaporDexAggregator;
    s.vaporDEXAdapter = _args.vaporDexAdapter;
    s.USDC = _args.usdc;
    s.VAPE = _args.vape;
    s.WETH = _args.weth;
    s.launchFee = _args.launchFee;
    s.minLiquidityETH = _args.minLiquidityETH;
    s.minLockDuration = _args.minLockDuration;
    s.sablier = _args.sablier;
    s.nonFungiblePositionManager = _args.nonFungiblePositionManager;
    s.teamMultisig = _args.teamMultisig;
    s.slippage = _args.slippage;
  }
}
