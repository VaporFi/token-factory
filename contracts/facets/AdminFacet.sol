// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { AppStorage, Modifiers } from "../libraries/LibAppStorage.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Token } from "../interfaces/IERC20Token.sol";

error AdminFacet__Invalid();
error AdminFacet__ZeroAddress();
error AdminFacet__InsufficientBalance();

contract AdminFacet is Modifiers {
  event MinimumLiquidityETHUpdated(uint256 _liquidity);
  event SlippageUpdated(uint256 _slippage);
  event MinimumLockDurationUpdated(uint40 _lockDuration);
  event LaunchFeeUpdated(uint256 _launchFee);
  event VaporDEXAdapterUpdated(address _vaporDexAdapter);
  event EmergencyWithdraw(address indexed _token, uint256 indexed _balance, address _to);

  /**
   * @dev Sets the minimum liquidity for creating new tokens.
   * @param _liquidity New liquidity.
   */

  function setMinimumLiquidityETH(uint256 _liquidity) external onlyOwner {
    if (_liquidity == 0) {
      revert AdminFacet__Invalid();
    }
    s.minLiquidityETH = _liquidity;
    emit MinimumLiquidityETHUpdated(_liquidity);
  }

  /**
   * @dev Sets the minimum liquidity for creating new tokens.
   * @param _slippage New lock duration in days.
   */

  function setSlippage(uint256 _slippage) external onlyOwner {
    s.slippage = _slippage;
    emit SlippageUpdated(_slippage);
  }

  /**
   * @dev Sets the minimum liquidity for creating new tokens.
   * @param _lockDuration New lock duration in days.
   */

  function setMinLockDuration(uint40 _lockDuration) external onlyOwner {
    if (_lockDuration == 0) {
      revert AdminFacet__Invalid();
    }
    s.minLockDuration = _lockDuration;
    emit MinimumLockDurationUpdated(_lockDuration);
  }

  /**
   * @dev Sets the launch fee for creating new tokens.
   * @param _launchFee New launch fee in USDC.
   */

  function setLaunchFee(uint256 _launchFee) external onlyOwner {
    if (_launchFee == 0) {
      revert AdminFacet__Invalid();
    }
    s.launchFee = _launchFee;
    emit LaunchFeeUpdated(_launchFee);
  }

  /**
   * @dev Sets the VaporDEX adapter address.
   * @param _vaporDexAdapter New VaporDEX adapter address.
   */

  function setVaporDEXAdapter(address _vaporDexAdapter) external onlyOwner {
    if (_vaporDexAdapter == s.vaporDEXAdapter || _vaporDexAdapter == address(0)) {
      revert AdminFacet__Invalid();
    }
    s.vaporDEXAdapter = _vaporDexAdapter;
    emit VaporDEXAdapterUpdated(_vaporDexAdapter);
  }

  /**
   * @dev Withdraws any stuck tokens (LP Or USDC) to the specified address.
   * @param _token Address of the token to be withdrawn.
   * @param _to Address to which the tokens are withdrawn.
   */

  function emergencyWithdraw(address _token, address _to) external onlyOwner {
    if (_to == address(0) || _token == address(0)) {
      revert AdminFacet__ZeroAddress();
    }
    IERC20 token = IERC20(_token);
    uint256 balance = token.balanceOf(address(this));
    if (balance == 0) {
      revert AdminFacet__InsufficientBalance();
    }
    token.transfer(_to, balance);
    emit EmergencyWithdraw(_token, balance, _to);
  }

  /**
   * @dev Retrieves the token launch information for a given owner.
   * @param _owner The address of the owner.
   * @return An array of token addresses associated with the owner.
   */
  function getTokenLaunches(address _owner) external view returns (address[] memory) {
    return s.userToTokens[_owner];
  }

  /**
   * @dev Retrieves the details of a token.
   * @param _token The address of the token.
   * @return deployer The address of the token's deployer.
   * @return tokenAddress The address of the token.
   * @return liquidityPool The address of the token's liquidity pool.
   * @return tradingStartsAt The timestamp when trading starts for the token.
   * @return streamId The stream ID associated with the token's liquidity lock. Returns 0 if burned.
   */
  function getTokenDetails(
    address _token
  )
    public
    view
    returns (address deployer, address tokenAddress, address liquidityPool, uint256 tradingStartsAt, uint256 streamId)
  {
    IERC20Token token = IERC20Token(_token);
    deployer = token.deployer();
    tokenAddress = address(token);
    liquidityPool = token.liquidityPool();
    tradingStartsAt = token.tradingStartsAt();
    streamId = s.liquidityLocks[deployer][tokenAddress];
  }

  function getLaunchFee() external view returns (uint256) {
    return s.launchFee;
  }

  function getVaporDEXAdapter() external view returns (address) {
    return s.vaporDEXAdapter;
  }

  /**
   * @dev Sets the Stratosphere address as the admin of the TokenFactoryDiamond.
   * @param _stratosphere The address of the Stratosphere NFT collection.
   */
  function setStratosphere(address _stratosphere) external onlyOwner {
    s.stratosphere = _stratosphere;
  }
}
