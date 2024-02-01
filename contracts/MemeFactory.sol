// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IVaporDEXFactory} from "./interfaces/IVaporDEXFactory.sol";
import {IVaporDEXRouter} from "./interfaces/IVaporDEXRouter.sol";
import {Token} from "./Token.sol";
import {ISablierV2LockupLinear} from "@sablier/v2-core/src/interfaces/ISablierV2LockupLinear.sol";
import {LockupLinear} from "@sablier/v2-core/src/types/DataTypes.sol";

error MemeFactory__WrongConstructorArguments();
error MemeFactory__LiquidityStillLocked();
error MemeFactory__Unauthorized();
error MemeFactory__ZeroAddress();
error MemeFactory__WrongLaunchArguments();
error MemeFactory__InsufficientBalance();
error MemeFactory__Invalid();

contract MemeFactory is Ownable {
    address public immutable factory;
    address public immutable router;
    address public immutable stratosphere;
    address public immutable vaporDexAggregator;
    address public immutable WETH;
    address public immutable USDC;
    address public vaporDexAdapter;
    uint256 public launchFee;

    // Sablier

    ISablierV2LockupLinear public immutable sablier;

    event TokenLaunched(
        address indexed _tokenAddress,
        address indexed _pairAddress,
        bool _liquidityLocked
    );

    event StreamCreated(uint256 indexed _streamId);
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
        address _vaporDexAdapter,
        address _usdc,
        uint256 _launchFee,
        ISablierV2LockupLinear _sablier
    ) Ownable(_owner) {
        if (
            _owner == address(0) ||
            _routerAddress == address(0) ||
            _stratosphereAddress == address(0) ||
            _vaporDexAggregator == address(0) ||
            _vaporDexAdapter == address(0) ||
            _usdc == address(0) ||
            _launchFee == 0 ||
            address(_sablier) == address(0)
        ) {
            revert MemeFactory__WrongConstructorArguments();
        }

        router = _routerAddress;
        IVaporDEXRouter _router = IVaporDEXRouter(_routerAddress);
        factory = _router.factory();
        WETH = _router.WETH();
        USDC = _usdc;
        stratosphere = _stratosphereAddress;
        vaporDexAggregator = _vaporDexAggregator;
        vaporDexAdapter = _vaporDexAdapter;
        launchFee = _launchFee;
        sablier = _sablier;
    }

    function launch(
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply,
        uint256 _tradingStartsAt,
        bool _burnLiquidity
    ) external payable returns (address _pair, address _tokenAddress) {
        // Step 0: Transfer Fee
        _transferLaunchFee(msg.sender);

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

        // Step 6: Lock Or Burn Liquidity

        IERC20 _lpToken = IERC20(_pair);

        if (_burnLiquidity) {
            // Burn Liquidity
        } else {
            // Lock Liquidity
            // Declare the params struct
            LockupLinear.CreateWithDurations memory params;

            // Declare the function parameters
            params.sender = address(this); // The sender will be able to cancel the stream
            params.recipient = msg.sender; // The recipient of the streamed assets
            params.totalAmount = uint128(_lpToken.balanceOf(address(this))); // Total amount is the amount inclusive of all fees
            params.asset = IERC20(USDC); // The streaming asset
            params.cancelable = false; // Whether the stream will be cancelable or not
            params.transferable = true; // Whether the stream will be transferrable or not
            params.durations = LockupLinear.Durations({
                cliff: 365 days, // Assets will be unlocked only after the cliff period
                total: 0 days // TODO: Set this to the total lockup period
            });

            // Create the stream

            uint256 streamId = sablier.createWithDurations(params);

            emit StreamCreated(streamId);
        }

        emit TokenLaunched(_tokenAddress, _pair, true);
    }

    function unlockLiquidityTokens(address _pair, address _receiver) external {
        emit LiquidityTokensUnlocked(_pair, _receiver);
    }

    function transferLock(address _pair, address _to) external {
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

    function setLaunchFee(uint256 _launchFee) public onlyOwner {
        if (_launchFee == 0) {
            revert MemeFactory__Invalid();
        }
        launchFee = _launchFee;
    }

    function setVaporDEXAdapter(address _vaporDexAdapter) public onlyOwner {
        if (_vaporDexAdapter == vaporDexAdapter) {
            revert MemeFactory__Invalid();
        }
        vaporDexAdapter = _vaporDexAdapter;
    }

    function _transferLaunchFee(address _from) internal {
        IERC20 _usdc = IERC20(USDC);
        if (_usdc.balanceOf(_from) < launchFee) {
            revert MemeFactory__InsufficientBalance();
        }
        _usdc.transferFrom(_from, address(this), launchFee);
    }

    function withdrawFee(address _to) public onlyOwner {
        IERC20 _usdc = IERC20(USDC);
        _usdc.transfer(_to, _usdc.balanceOf(address(this)));
    }
}
