// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/// @title IDiamondLoupe
/// @author Modified from Nick Mudge: https://github.com/mudgen/diamond-3-hardhat
/// @dev EIP-2535 "Diamond" standard
interface IDiamondLoupe {
    ///////////////
    /// STORAGE ///
    ///////////////

    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /////////////
    /// LOGIC ///
    /////////////

    function facetAddress(
        bytes4 selector
    ) external view returns (address facetAddress);

    function facetAddresses()
        external
        view
        returns (address[] memory facetAddresses);

    function facetFunctionSelectors(
        address facet
    ) external view returns (bytes4[] memory facetFunctionSelectors);

    function facets() external view returns (Facet[] memory facets);
}
