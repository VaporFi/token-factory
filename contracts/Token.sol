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

contract Token is ERC20, ERC20Permit, Ownable {
    address public liquidityPool;
    uint256 public immutable maxHoldingAmount;
    uint256 public immutable tradingStartsAt;
    IStratosphere public immutable stratosphere;

    mapping(address => bool) public whitelist;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _supply,
        address _stratosphereAddress,
        address _owner,
        uint256 _tradingStartsAt,
        address[] memory _whitelist
    ) ERC20(_name, _symbol) ERC20Permit(_name) Ownable(_owner) {
        whitelist[msg.sender] = true;
        stratosphere = IStratosphere(_stratosphereAddress);
        _mint(msg.sender, _supply);
        maxHoldingAmount = _percentage(_supply, 100); // 1% of total supply
        tradingStartsAt = _tradingStartsAt;

        for (uint256 i = 0; i < _whitelist.length; i++) {
            whitelist[_whitelist[i]] = true;
        }
    }

    function setLiquidityPool(address _liquidityPool) external onlyOwner {
        if (_liquidityPool == address(0)) {
            revert Token__MissingLiquidityPool();
        }
        liquidityPool = _liquidityPool;
        whitelist[_liquidityPool] = true;
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

        if (whitelist[from] || whitelist[to]) {
            return;
        }

        if (_secondsSinceTradingStarted < 1 hours) {
            _enforceStratosphereHolder(to);
            _enforceAntiWhale(to, value);
        } else if (_secondsSinceTradingStarted < 24 hours) {
            _enforceAntiWhale(to, value);
        }
    }

    function _enforceStratosphereHolder(address _address) internal view {
        // Checking Main and All Linked Wallets
        if (stratosphere.tokenIdOf(_address) == 0) {
            revert Token__NonStratosphereNFTHolder();
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

    function _percentage(
        uint256 _number,
        uint256 _percentage
    ) internal pure returns (uint256) {
        return (_number * _percentage) / 10_000;
    }
}
