// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { AppStorage } from "../libraries/LibAppStorage.sol";
import { ISablierV2LockupLinear } from "@sablier/v2-core/src/interfaces/ISablierV2LockupLinear.sol";

error LiquidityLockFacet__Unauthorized();
error LiquidityLockFacet__ZeroAddress();
error LiquidityLockFacet__LiquidityLockedOrDepleted();

contract LiquidityLockFacet {
  AppStorage internal s;

  event LiquidityTokensUnlocked(address _tokenAddress, address _receiver);
  event LiquidityTransferred(address _tokenAddress, address _to);

  /**
   * @dev Unlocks liquidity tokens for the specified pair and recipient.
   * @param _tokenAddress Address of the token pair.
   * @param _receiver Address of the recipient of unlocked tokens.
   * @notice It is recommended to direct the user to Sablier UI for better error handling.
   */
  function unlockLiquidityTokens(address _tokenAddress, address _receiver) external {
    if (_receiver == address(0)) {
      revert LiquidityLockFacet__ZeroAddress();
    }
    uint256 streamId = s.liquidityLocks[msg.sender][_tokenAddress];

    if (streamId == 0) {
      revert LiquidityLockFacet__Unauthorized();
    }
    ISablierV2LockupLinear sablier = ISablierV2LockupLinear(s.sablier);

    uint256 withdrawableAmount = sablier.withdrawableAmountOf(streamId);
    if (withdrawableAmount == 0) {
      revert LiquidityLockFacet__LiquidityLockedOrDepleted();
    }

    sablier.withdrawMax({ streamId: streamId, to: _receiver }); // Other reverts are handled by Sablier

    emit LiquidityTokensUnlocked(_tokenAddress, _receiver);
  }

  /**
   * @dev Transfers the locked liquidity to the specified recipient for the given token.
   * @param _tokenAddress Address of the token.
   * @param _to Address of the recipient.
   */
  function transferLock(address _tokenAddress, address _to) external {
    uint256 streamId = s.liquidityLocks[msg.sender][_tokenAddress];
    ISablierV2LockupLinear sablier = ISablierV2LockupLinear(s.sablier);
    if (streamId == 0 || _to == address(0) || sablier.isTransferable(streamId) == false) {
      revert LiquidityLockFacet__Unauthorized();
    }

    s.liquidityLocks[_to][_tokenAddress] = streamId;
    s.liquidityLocks[msg.sender][_tokenAddress] = 0;

    sablier.transferFrom({ from: msg.sender, to: _to, tokenId: streamId }); // Other reverts are handled by Sablier

    emit LiquidityTransferred(_tokenAddress, _to);
  }
}
