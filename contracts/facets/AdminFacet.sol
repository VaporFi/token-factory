// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {AppStorage, Modifiers} from "../libraries/LibAppStorage.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error AdminFacet__Invalid();
error AdminFacet__ZeroAddress();

contract AdminFacet is Modifiers {
    event MinimumLiquidityETHUpdated(uint256 _liquidity);
    event SlippageUpdated(uint256 _slippage);
    event MinimumLockDurationUpdated(uint40 _lockDuration);
    event LaunchFeeUpdated(uint256 _launchFee);
    event VaporDEXAdapterUpdated(address _vaporDexAdapter);
    event AccumulatedFeesWithdrawn(address _to, uint256 _amount);

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
        if (
            _vaporDexAdapter == s.VaporDEXAdapter ||
            _vaporDexAdapter == address(0)
        ) {
            revert AdminFacet__Invalid();
        }
        s.VaporDEXAdapter = _vaporDexAdapter;
        emit VaporDEXAdapterUpdated(_vaporDexAdapter);
    }

    /**
     * @dev Withdraws any remaining USDC fees to the specified address.
     * @param _to Address to which the remaining fees are withdrawn.
     */

    function withdrawFee(address _to) external onlyOwner {
        if (_to == address(0)) {
            revert AdminFacet__ZeroAddress();
        }
        IERC20 _usdc = IERC20(s.USDC);
        _usdc.transfer(_to, _usdc.balanceOf(address(this)));
        emit AccumulatedFeesWithdrawn(_to, _usdc.balanceOf(address(this)));
    }
}
