// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { CREATE3 } from "solmate/src/utils/CREATE3.sol";

contract CREATE3Factory {
  function deploy(bytes32 salt, bytes memory creationCode) external payable returns (address deployed) {
    // hash salt with the deployer address to give each deployer its own namespace
    salt = keccak256(abi.encodePacked(msg.sender, salt));
    return CREATE3.deploy(salt, creationCode, msg.value);
  }

  function getDeployed(address deployer, bytes32 salt) external view returns (address deployed) {
    // hash salt with the deployer address to give each deployer its own namespace
    salt = keccak256(abi.encodePacked(deployer, salt));
    return CREATE3.getDeployed(salt);
  }
}
