// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Token is IERC20 {
  function setLiquidityPool(address _pool) external;

  function renounceOwnership() external;

  function deployer() external view returns (address);

  function liquidityPool() external view returns (address);

  function tradingStartsAt() external view returns (uint256);
}
