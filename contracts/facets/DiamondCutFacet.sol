// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IDiamondCut} from "../interfaces/IDiamondCut.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";

/// @title DiamondCutFacet
/// @author Modified from Nick Mudge: https://github.com/mudgen/diamond-3-hardhat
/// @notice Facet in charge of the diamond cut
/// @dev Utilizes 'IDiamondCut' and 'LDiamond'
contract DiamondCutFacet is IDiamondCut {
    /// @notice Diamond cut
    /// @param _cut Facet cut
    /// @param _init Address of the initialization contract
    /// @param _data Data
    function diamondCut(
        FacetCut[] calldata _cut,
        address _init,
        bytes calldata _data
    ) external {
        LibDiamond.enforceIsOwner();
        LibDiamond.diamondCut(_cut, _init, _data);
    }
}
