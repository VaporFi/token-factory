// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IStratosphere} from "./interfaces/IStratosphere.sol";

error Token__MissingLiquidityPool();
error Token__ExceedsMaximumHolding();
error Token__TradingNotStarted();
error Token__NonStratosphereNFTHolder();
error Token__BotDetected();

contract Token is ERC20, ERC20Permit, Ownable {
    address public liquidityPool;
    address public immutable dexAggregator;
    address public immutable dexAdapter;
    uint256 public immutable maxHoldingAmount;
    uint256 public immutable tradingStartsAt;
    IStratosphere public immutable stratosphere;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _supply,
        address _stratosphereAddress,
        address _owner,
        uint256 _tradingStartsAt,
        address _dexAggregator,
        address _dexAdapter
    ) ERC20(_name, _symbol) ERC20Permit(_name) Ownable(_owner) {
        stratosphere = IStratosphere(_stratosphereAddress);
        _mint(msg.sender, _supply);
        maxHoldingAmount = _percentage(_supply, 100); // 1% of total supply
        tradingStartsAt = _tradingStartsAt;
        dexAggregator = _dexAggregator;
        dexAdapter = _dexAdapter;
    }

    function setLiquidityPool(address _liquidityPool) external onlyOwner {
        if (_liquidityPool == address(0)) {
            revert Token__MissingLiquidityPool();
        }
        liquidityPool = _liquidityPool;
    }

   /// @dev Replacement for _beforeTokenTransfer() since OZ v5
    function _update(
        address from,
        address to,
        uint256 value
    ) internal virtual override {
        super._update(from, to, value);
        uint256 _tradingStartsAt = tradingStartsAt;

        if (liquidityPool == address(0)) {
            require(
                from == owner() || to == owner(),
                "Patience - Trading Not Started Yet!"
            );
            return;
        }

        if (block.timestamp < _tradingStartsAt) {
            revert Token__TradingNotStarted();
        }

        uint256 _secondsSinceTradingStarted = block.timestamp -
            _tradingStartsAt;

        if (_secondsSinceTradingStarted > 24 hours) {
            return;
        }

        if (_secondsSinceTradingStarted < 1 hours) {
            _enforceAntiWhale(to, value);
            if (!(isStratosphereMemberOrAdmin(from) && isStratosphereMemberOrAdmin(to))) {
                revert Token__NonStratosphereNFTHolder();
            }
        } else if (_secondsSinceTradingStarted < 24 hours) {
            _enforceAntiWhale(to, value);
        }
    }

    function _enforceAntiWhale(address to, uint256 value) internal view {
        if (to != liquidityPool) {
            uint256 newBalance = balanceOf(to) + value;
            if (newBalance > maxHoldingAmount) {
                revert Token__ExceedsMaximumHolding();
            }
        }
    }
    
    // Can be exploited using "Constructor" method by serves our purpose
   // Minting strat requires less effort than hack
    function isStratosphereMemberOrAdmin(address _address) internal view returns (bool pass) {
        if (_address == dexAggregator || _address == dexAdapter || stratosphere.tokenIdOf(_address) != 0 ||
        _address == liquidityPool) {
            pass = true;
        }
    }

    function _percentage(
        uint256 _number,
        uint256 _percentageBasisPoints // Example: 1% is 100
    ) internal pure returns (uint256) {
        return (_number * _percentageBasisPoints) / 10_000;
    }
}
