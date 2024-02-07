// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

/// @title IAuthenticationController
/// @author Jose Mejias
/// @notice Interface for AuthenticationController
interface IAuthenticationController {
    function associatedTokenOf(address _account) external view returns (uint256);
    function setAuthorizedToken(address account, uint256 tokenId) external;
    function setStratosphere(address newStratosphereAddress) external;
    function authorizedTokenOf(address account) external view returns (uint256);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
}