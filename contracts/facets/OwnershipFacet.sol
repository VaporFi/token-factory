// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { LibDiamond } from "../libraries/LibDiamond.sol";
import { IERC173 } from "../interfaces/IERC173.sol";

/// @title OwnershipFacet
/// @author Modified from Nick Mudge: https://github.com/mudgen/diamond-3-hardhat
/// @notice Facet in charge of administrating the ownership of the contract
/// @notice Utilizes 'IERC173' and 'LDiamond'
contract OwnershipFacet is IERC173 {
  /// @notice Get contract owner
  function owner() external view returns (address owner_) {
    owner_ = LibDiamond.contractOwner();
  }

  /// @notice Transfer ownership
  /// @param _owner New owner
  function transferOwnership(address _owner) external {
    LibDiamond.enforceIsOwner();
    LibDiamond.updateContractOwner(_owner);
  }
}
