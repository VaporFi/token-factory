// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IVaporDEXFactory} from "./interfaces/IVaporDEXFactory.sol";
import {IVaporDEXRouter} from "./interfaces/IVaporDEXRouter.sol";
import {Token} from "./Token.sol";

error MemeFactory__WrongConstructorArguments();
error MemeFactory__LiquidityStillLocked();
error MemeFactory__Unauthorized();
error MemeFactory__ZeroAddress();
error MemeFactory__WrongLaunchArguments();

contract MemeFactory is Ownable {
    address public immutable factory;
    address public immutable router;
    address public immutable WETH;
    address public immutable stratosphere;
    address public immutable vaporDexAggregator;
    address public immutable vaporDexAdapter;

    struct LiquidityLock {
        address owner;
        address pair;
        uint256 unlocksAt;
    }
    mapping(address => LiquidityLock) private _pairInfo;

    event TokenLaunched(
        address indexed _tokenAddress,
        address indexed _pairAddress
    );
    event LiquidityTokensUnlocked(
        address indexed _pairAddress,
        address indexed _receiver
    );
    event LiquidityTransferred(
        address indexed _pairAddress,
        address indexed _to
    );

    constructor(
        address _owner,
        address _routerAddress,
        address _stratosphereAddress,
        address _vaporDexAggregator,
        address _vaporDexAdapter
    ) Ownable(_owner) {
        if (
            _checkParams(
                _owner,
                _routerAddress,
                _stratosphereAddress,
                _vaporDexAggregator,
                _vaporDexAdapter
            )
        ) {
            revert MemeFactory__WrongConstructorArguments();
        }

        router = _routerAddress;
        IVaporDEXRouter _router = IVaporDEXRouter(_routerAddress);
        factory = _router.factory();
        WETH = _router.WETH();
        stratosphere = _stratosphereAddress;
        vaporDexAggregator = _vaporDexAggregator;
        vaporDexAdapter = _vaporDexAdapter;
    }

    function launch(
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply,
        uint256 _tradingStartsAt
    ) external payable returns (address _pair, address _tokenAddress) {
        // Step 1: Create the token
        Token _token = _createToken(
            _name,
            _symbol,
            _totalSupply,
            _tradingStartsAt,
            vaporDexAggregator,
            vaporDexAdapter
        );
        _tokenAddress = address(_token);

        // Step 2: Create the pair
        IVaporDEXFactory _factory = IVaporDEXFactory(factory);
        _pair = _factory.createPair(_tokenAddress, WETH);
        _token.approve(router, _totalSupply);
        _token.approve(_pair, _totalSupply);

        // Step 2: Add Liquidity
        IVaporDEXRouter _router = IVaporDEXRouter(router);
        _router.addLiquidityETH{value: msg.value}(
            _tokenAddress,
            _totalSupply,
            _totalSupply,
            msg.value,
            address(this),
            block.timestamp + 10 minutes
        );
        // Step 3: Get the pair address
        _pair = IVaporDEXFactory(factory).getPair(_tokenAddress, WETH);
        if (_pair == address(0)) {
            revert MemeFactory__ZeroAddress();
        }
        // Step 4: Set the LP address in the token
        _token.setLiquidityPool(_pair);
        // Step 5: Renounce ownership of the token
        _token.renounceOwnership();
        // Step 6: lock the LP tokens for 365 days
        _pairInfo[_pair] = LiquidityLock({
            owner: msg.sender,
            pair: _pair,
            unlocksAt: block.timestamp + 365 days
        });

        emit TokenLaunched(_tokenAddress, _pair);
    }

    function unlockLiquidityTokens(address _pair, address _receiver) external {
        if (_pairInfo[_pair].unlocksAt > block.timestamp) {
            revert MemeFactory__LiquidityStillLocked();
        }
        if (_pairInfo[_pair].owner != msg.sender) {
            revert MemeFactory__Unauthorized();
        }
        _pairInfo[_pair].owner = address(0);
        _pairInfo[_pair].pair = address(0);
        _pairInfo[_pair].unlocksAt = 0;

        ERC20 _lpToken = ERC20(_pair);
        _lpToken.transfer(_receiver, _lpToken.balanceOf(address(this)));

        emit LiquidityTokensUnlocked(_pair, _receiver);
    }

    function transferLock(address _pair, address _to) external {
        address _currentOwner = _pairInfo[_pair].owner;
        if (msg.sender != _currentOwner) {
            revert MemeFactory__Unauthorized();
        }

        _pairInfo[_pair].owner = _to;

        emit LiquidityTransferred(_pair, _to);
    }

    function _createToken(
        string memory name,
        string memory symbol,
        uint256 totalSupply,
        uint256 _tradingStartsAt,
        address dexAggregator,
        address dexAdapter
    ) internal returns (Token _token) {
        if (totalSupply == 0 || _tradingStartsAt < block.timestamp) {
            revert MemeFactory__WrongLaunchArguments();
        }
        _token = new Token(
            name,
            symbol,
            totalSupply,
            stratosphere,
            address(this),
            _tradingStartsAt,
            dexAggregator,
            dexAdapter
        );
    }

    function _checkParams(
        address _owner,
        address _routerAddress,
        address _stratosphereAddress,
        address _vaporDexAggregator,
        address _vaporDexAdapter
    ) internal pure returns (bool shouldRevert) {
        if (
            _owner == address(0) ||
            _routerAddress == address(0) ||
            _stratosphereAddress == address(0) ||
            _vaporDexAggregator == address(0) ||
            _vaporDexAdapter == address(0) ||
            _owner == _routerAddress ||
            _owner == _stratosphereAddress ||
            _owner == _vaporDexAggregator ||
            _owner == _vaporDexAdapter ||
            _routerAddress == _stratosphereAddress ||
            _routerAddress == _vaporDexAggregator ||
            _routerAddress == _vaporDexAdapter ||
            _stratosphereAddress == _vaporDexAggregator ||
            _stratosphereAddress == _vaporDexAdapter ||
            _vaporDexAggregator == _vaporDexAdapter
        ) {
            shouldRevert = true;
        }
        shouldRevert = false;
    }
}
