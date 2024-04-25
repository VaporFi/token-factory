// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.25;

import { Test } from "forge-std/Test.sol";
import { IDiamondCut } from "contracts/interfaces/IDiamondCut.sol";

import { TokenFactoryDiamond } from "contracts/TokenFactoryDiamond.sol";
import { DiamondCutFacet } from "contracts/facets/DiamondCutFacet.sol";
import { DiamondLoupeFacet } from "contracts/facets/DiamondLoupeFacet.sol";
import { OwnershipFacet } from "contracts/facets/OwnershipFacet.sol";
import { AuthorizationFacet } from "contracts/facets/AuthorizationFacet.sol";
import { DiamondInit } from "contracts/upgradeInitializers/DiamondInit.sol";
import { LaunchERC20Facet } from "contracts/facets/LaunchERC20Facet.sol";
import { AdminFacet } from "contracts/facets/AdminFacet.sol";
import { LiquidityLockFacet } from "contracts/facets/LiquidityLockFacet.sol";

contract TokenFactoryDiamondBaseTest is Test {
  IDiamondCut.FacetCut[] internal _cut;
  address internal _diamondOwner = makeAddr("diamondOwner");

  function createDiamond(DiamondInit.DeployArgs memory _initArgs) internal returns (TokenFactoryDiamond) {
    DiamondCutFacet diamondCut = new DiamondCutFacet();
    TokenFactoryDiamond diamond = new TokenFactoryDiamond(_diamondOwner, address(diamondCut));
    DiamondInit diamondInit = new DiamondInit();

    setDiamondLoupeFacet();
    setOwnershipFacet();
    setAuthorizationFacet();
    setLaunchERC20Facet();
    setAdminFacet();
    setLiquidityLockFacet();

    bytes memory data = abi.encodeWithSelector(DiamondInit.init.selector, _initArgs);
    DiamondCutFacet(address(diamond)).diamondCut(_cut, address(diamondInit), data);

    delete _cut;
    return diamond;
  }

  function setDiamondLoupeFacet() private {
    DiamondLoupeFacet diamondLoupe = new DiamondLoupeFacet();
    bytes4[] memory functionSelectors;
    functionSelectors = new bytes4[](5);
    functionSelectors[0] = DiamondLoupeFacet.facetFunctionSelectors.selector;
    functionSelectors[1] = DiamondLoupeFacet.facets.selector;
    functionSelectors[2] = DiamondLoupeFacet.facetAddress.selector;
    functionSelectors[3] = DiamondLoupeFacet.facetAddresses.selector;
    functionSelectors[4] = DiamondLoupeFacet.supportsInterface.selector;
    _cut.push(
      IDiamondCut.FacetCut({
        facetAddress: address(diamondLoupe),
        action: IDiamondCut.FacetCutAction.Add,
        functionSelectors: functionSelectors
      })
    );
  }

  function setOwnershipFacet() private {
    OwnershipFacet ownership = new OwnershipFacet();
    bytes4[] memory functionSelectors;
    functionSelectors = new bytes4[](2);
    functionSelectors[0] = OwnershipFacet.owner.selector;
    functionSelectors[1] = OwnershipFacet.transferOwnership.selector;
    _cut.push(
      IDiamondCut.FacetCut({
        facetAddress: address(ownership),
        action: IDiamondCut.FacetCutAction.Add,
        functionSelectors: functionSelectors
      })
    );
  }

  function setAuthorizationFacet() private {
    AuthorizationFacet authorization = new AuthorizationFacet();
    bytes4[] memory functionSelectors;
    functionSelectors = new bytes4[](3);
    functionSelectors[0] = AuthorizationFacet.authorized.selector;
    functionSelectors[1] = AuthorizationFacet.authorize.selector;
    functionSelectors[2] = AuthorizationFacet.unAuthorize.selector;
    _cut.push(
      IDiamondCut.FacetCut({
        facetAddress: address(authorization),
        action: IDiamondCut.FacetCutAction.Add,
        functionSelectors: functionSelectors
      })
    );
  }

  function setLaunchERC20Facet() private {
    LaunchERC20Facet launchERC20 = new LaunchERC20Facet();
    bytes4[] memory functionSelectors;
    functionSelectors = new bytes4[](1);
    functionSelectors[0] = LaunchERC20Facet.launchERC20.selector;
    _cut.push(
      IDiamondCut.FacetCut({
        facetAddress: address(launchERC20),
        action: IDiamondCut.FacetCutAction.Add,
        functionSelectors: functionSelectors
      })
    );
  }

  function setAdminFacet() private {
    AdminFacet admin = new AdminFacet();
    bytes4[] memory functionSelectors;
    functionSelectors = new bytes4[](8);
    functionSelectors[0] = AdminFacet.setMinimumLiquidityETH.selector;
    functionSelectors[1] = AdminFacet.setSlippage.selector;
    functionSelectors[2] = AdminFacet.setMinLockDuration.selector;
    functionSelectors[3] = AdminFacet.setLaunchFee.selector;
    functionSelectors[4] = AdminFacet.setVaporDEXAdapter.selector;
    functionSelectors[5] = AdminFacet.emergencyWithdraw.selector;
    functionSelectors[6] = AdminFacet.getLaunchFee.selector;
    functionSelectors[7] = AdminFacet.getVaporDEXAdapter.selector;
    _cut.push(
      IDiamondCut.FacetCut({
        facetAddress: address(admin),
        action: IDiamondCut.FacetCutAction.Add,
        functionSelectors: functionSelectors
      })
    );
  }

  function setLiquidityLockFacet() private {
    LiquidityLockFacet liquidityLock = new LiquidityLockFacet();
    bytes4[] memory functionSelectors;
    functionSelectors = new bytes4[](2);
    functionSelectors[0] = LiquidityLockFacet.unlockLiquidityTokens.selector;
    functionSelectors[1] = LiquidityLockFacet.transferLock.selector;
    _cut.push(
      IDiamondCut.FacetCut({
        facetAddress: address(liquidityLock),
        action: IDiamondCut.FacetCutAction.Add,
        functionSelectors: functionSelectors
      })
    );
  }
}
