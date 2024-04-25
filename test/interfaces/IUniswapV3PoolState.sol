// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.25;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
  /// @notice The currently in range liquidity available to the pool
  /// @dev This value has no relationship to the total liquidity across all ticks
  function liquidity() external view returns (uint128);
}
