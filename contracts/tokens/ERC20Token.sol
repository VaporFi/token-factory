// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IStratosphere } from "../interfaces/IStratosphere.sol";

error ERC20Token__MissingLiquidityPool();
error ERC20Token__ExceedsMaximumHolding();
error ERC20Token__TradingNotStarted();
error ERC20Token__NonStratosphereNFTHolder();
error ERC20Token__BotDetected();

contract ERC20Token is ERC20, ERC20Permit, Ownable {
  address public liquidityPool;
  address public immutable dexAggregator;
  address public immutable dexAdapter;
  uint256 public immutable maxHoldingAmount;
  uint256 public immutable tradingStartsAt;
  address public immutable deployer;
  IStratosphere public immutable stratosphere;
  bool public immutable isStratosphereEnabled;

  constructor(
    string memory _name,
    string memory _symbol,
    uint256 _supply,
    address _stratosphereAddress,
    address _owner,
    uint256 _tradingStartsAt,
    address _dexAggregator,
    address _dexAdapter,
    address _deployer,
    bool _isStratosphereEnabled
  ) ERC20(_name, _symbol) ERC20Permit(_name) Ownable(_owner) {
    stratosphere = IStratosphere(_stratosphereAddress);
    _mint(msg.sender, _supply);
    maxHoldingAmount = _percentage(_supply, 100); // 1% of total supply
    tradingStartsAt = _tradingStartsAt;
    dexAggregator = _dexAggregator;
    dexAdapter = _dexAdapter;
    isStratosphereEnabled = _isStratosphereEnabled;
    deployer = _deployer;
  }

  function setLiquidityPool(address _liquidityPool) external onlyOwner {
    if (_liquidityPool == address(0)) {
      revert ERC20Token__MissingLiquidityPool();
    }
    liquidityPool = _liquidityPool;
  }

  /// @dev Replacement for _beforeTokenTransfer() since OZ v5
  function _update(address from, address to, uint256 value) internal virtual override {
    super._update(from, to, value);
    uint256 _tradingStartsAt = tradingStartsAt;

    if (liquidityPool == address(0)) {
      require(from == owner() || to == owner(), "Patience - Trading Not Started Yet!");
      return;
    }

    if (block.timestamp < _tradingStartsAt) {
      revert ERC20Token__TradingNotStarted();
    }

    uint256 _secondsSinceTradingStarted = block.timestamp - _tradingStartsAt;
    bool _isStratosphereEnabled = isStratosphereEnabled;
    uint16 _antiWhaleDuration = _getAntiWhaleDuration(_isStratosphereEnabled) * 1 hours;

    if (_secondsSinceTradingStarted > _antiWhaleDuration) {
      return;
    }

    if (_isStratosphereEnabled && _secondsSinceTradingStarted < 1 hours) {
      _enforceAntiWhale(to);
      if (!(_isStratosphereMemberOrAdmin(from) && _isStratosphereMemberOrAdmin(to))) {
        revert ERC20Token__NonStratosphereNFTHolder();
      }
    } else if (_secondsSinceTradingStarted < _antiWhaleDuration) {
      _enforceAntiWhale(to);
    }
  }

  function _enforceAntiWhale(address to) internal view {
    if (to != liquidityPool) {
      if (balanceOf(to) > maxHoldingAmount) {
        revert ERC20Token__ExceedsMaximumHolding();
      }
    }
  }

  function _isStratosphereMemberOrAdmin(address _address) internal view returns (bool pass) {
    if (
      _address == dexAggregator ||
      _address == dexAdapter ||
      stratosphere.tokenIdOf(_address) != 0 ||
      _address == liquidityPool
    ) {
      pass = true;
    }
  }

  function _percentage(
    uint256 _number,
    uint256 _percentageBasisPoints // Example: 1% is 100
  ) internal pure returns (uint256) {
    return (_number * _percentageBasisPoints) / 10_000;
  }

  function _getAntiWhaleDuration(bool _isStratosphereEnabled) internal pure returns (uint8) {
    if (_isStratosphereEnabled) {
      return 2;
    }
    return 1;
  }
}
