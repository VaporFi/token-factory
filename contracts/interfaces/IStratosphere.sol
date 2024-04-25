// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

interface IStratosphere {
  function tokenIdOf(address _owner) external view returns (uint256);

  function mint() external returns (uint256);
}
