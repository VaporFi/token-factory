// ███╗░░░███╗███████╗███╗░░░███╗███████╗  ███████╗░█████╗░░█████╗░████████╗░█████╗░██████╗░██╗░░░██╗
// ████╗░████║██╔════╝████╗░████║██╔════╝  ██╔════╝██╔══██╗██╔══██╗╚══██╔══╝██╔══██╗██╔══██╗╚██╗░██╔╝
// ██╔████╔██║█████╗░░██╔████╔██║█████╗░░  █████╗░░███████║██║░░╚═╝░░░██║░░░██║░░██║██████╔╝░╚████╔╝░
// ██║╚██╔╝██║██╔══╝░░██║╚██╔╝██║██╔══╝░░  ██╔══╝░░██╔══██║██║░░██╗░░░██║░░░██║░░██║██╔══██╗░░╚██╔╝░░
// ██║░╚═╝░██║███████╗██║░╚═╝░██║███████╗  ██║░░░░░██║░░██║╚█████╔╝░░░██║░░░╚█████╔╝██║░░██║░░░██║░░░
// ╚═╝░░░░░╚═╝╚══════╝╚═╝░░░░░╚═╝╚══════╝  ╚═╝░░░░░╚═╝░░╚═╝░╚════╝░░░░╚═╝░░░░╚════╝░╚═╝░░╚═╝░░░╚═╝░░░

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
error MemeFactory__LiquidityLockedOrDepleted();
error MemeFactory__Unauthorized();
error MemeFactory__ZeroAddress();
error MemeFactory__WrongLaunchArguments();
error MemeFactory__InsufficientBalance();
error MemeFactory__Invalid();
error MemeFactory__TranferFailed(address);
error MemeFactory__NotEnoughLiquidity();
error MemeFactory__MinimumLockDuration();

/// @title MemeFactory
/// @author Roy & Jose
/// @notice This contract is used to launch new tokens and create liquidity for them
/// @dev Utilizes 'Sablier' for liquidity locking
contract MemeFactory is Ownable {
    //////////////
    /// EVENTS ///
    //////////////

    event TokenLaunched(
        address indexed _tokenAddress,
        address indexed _pairAddress,
        bool _liquidityBurned
    );

    event StreamCreated(uint256 indexed _streamId);
    event LiquidityBurned(
        address indexed pair,
        address indexed _burner,
        uint256 _amount
    );
    event LiquidityTokensUnlocked(
        address indexed _pairAddress,
        address indexed _receiver
    );
    event LiquidityTransferred(
        address indexed _pairAddress,
        address indexed _to
    );
    event LaunchFeeUpdated(uint256 _newFee);
    event MinimumLiquidityETHUpdated(uint256 _newFee);
    event MinimumLockDurationUpdated(uint40 _newFee);
    event VaporDEXAdapterUpdated(address _newAdapter);
    event AccumulatedFeesWithdrawn(address _to, uint256 _amount);

    ///////////////
    /// STORAGE ///
    ///////////////

    address public immutable factory;
    address public immutable router;
    address public immutable stratosphere;
    address public immutable vaporDexAggregator;
    address public immutable WETH;
    address public immutable USDC;
    address public vaporDexAdapter;
    address public teamMultisig;
    uint256 public launchFee;
    uint256 public minLiquidityETH;
    uint40 public minLockDuration;

    // Sablier
    ISablierV2LockupLinear private immutable sablier;
    // Mapping to store the streamId for each pair and lp owner
    mapping(address => mapping(address => uint256)) private liquidityLocks;

    /////////////////////////
    ////// CONSTRUCTOR /////
    ////////////////////////

    /**
     * @dev MemeFactory constructor initializes the contract with required parameters.
     * @param _owner Address of the contract owner.
     * @param _routerAddress Address of the VaporDEXRouter contract.
     * @param _stratosphereAddress Address of the Stratosphere contract.
     * @param _vaporDexAggregator Address of the VaporDEX aggregator.
     * @param _vaporDexAdapter Address of the VaporDEX adapter.
     * @param _usdc Address of the USDC token.
     * @param _launchFee Launch fee in USDC.
     * @param _sablier Address of the Sablier contract.
     */
    constructor(
        address _owner,
        address _routerAddress,
        address _stratosphereAddress,
        address _vaporDexAggregator,
        address _vaporDexAdapter,
        address _teamMultisig,
        address _usdc,
        uint256 _launchFee,
        uint256 _minLiquidityETH,
        uint40 _minLockDuration,
        address _sablier
    ) Ownable(_owner) {
        // Check for valid constructor arguments
        if (
            _owner == address(0) ||
            _routerAddress == address(0) ||
            _stratosphereAddress == address(0) ||
            _vaporDexAggregator == address(0) ||
            _vaporDexAdapter == address(0) ||
            _usdc == address(0) ||
            _launchFee == 0 ||
            _sablier == address(0) ||
            _minLiquidityETH == 0 ||
            _minLockDuration == 0
        ) {
            revert MemeFactory__WrongConstructorArguments();
        }

        // Initialize variables
        router = _routerAddress;
        IVaporDEXRouter _router = IVaporDEXRouter(_routerAddress);
        factory = _router.factory();
        WETH = _router.WETH();
        USDC = _usdc;
        minLiquidityETH = _minLiquidityETH;
        minLockDuration = _minLockDuration;
        stratosphere = _stratosphereAddress;
        vaporDexAggregator = _vaporDexAggregator;
        teamMultisig = _teamMultisig;
        vaporDexAdapter = _vaporDexAdapter;
        launchFee = _launchFee;
        sablier = ISablierV2LockupLinear(_sablier);
    }

    /**
     * @dev Launches a new token with specified parameters.
     * @param _name Name of the token.
     * @param _symbol Symbol of the token.
     * @param _totalSupply Total supply of the token.
     * @param _tradingStartsAt Timestamp when trading starts for the token.
     * @param lockDuration Number of days to lock liquidity for.
     * @param _burnLiquidity Flag indicating whether to burn liquidity or lock it.
     * @return _pair Address of the created token pair.
     * @return _tokenAddress Address of the launched token.
     * @return streamId Stream ID if liquidity is locked, otherwise 0.
     */

    function launch(
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply,
        uint256 _tradingStartsAt,
        uint40 lockDuration,
        bool _burnLiquidity
    )
        external
        payable
        returns (address _pair, address _tokenAddress, uint256 streamId)
    {
        uint256 value = msg.value;
        if (value < minLiquidityETH) {
            revert MemeFactory__NotEnoughLiquidity();
        }
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
        _router.addLiquidityETH{value: value}(
            _tokenAddress,
            _totalSupply,
            _totalSupply,
            value,
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
            _lpToken.transfer(address(0), _lpToken.balanceOf(address(this)));
            emit LiquidityBurned(
                _pair,
                msg.sender,
                _lpToken.balanceOf(address(this))
            );
        } else {
            if (lockDuration < minLockDuration) {
                revert MemeFactory__MinimumLockDuration();
            }
            _lpToken.approve(
                address(sablier),
                _lpToken.balanceOf(address(this))
            );
            // Lock Liquidity
            // SablierV2
            LockupLinear.CreateWithDurations memory params;

            // Declare the function parameters
            params.sender = address(this); // The sender will be able to cancel the stream
            params.recipient = msg.sender; // The recipient of the streamed assets
            params.totalAmount = uint128(_lpToken.balanceOf(address(this))); // Total amount is the amount inclusive of all fees
            params.asset = _lpToken; // The streaming asset
            params.cancelable = false; // Whether the stream will be cancelable or not
            params.transferable = true; // Whether the stream will be transferrable or not
            params.durations = LockupLinear.Durations({
                cliff: lockDuration * 1 days - 1 seconds, // Assets will be unlocked only after the cliff period
                total: lockDuration * 1 days
            });

            // Create the stream
            streamId = sablier.createWithDurations(params);
            liquidityLocks[msg.sender][_pair] = streamId;

            emit StreamCreated(streamId);
        }

        emit TokenLaunched(_tokenAddress, _pair, _burnLiquidity);
    }

    /**
     * @dev Unlocks liquidity tokens for the specified pair and recipient.
     * @param _pair Address of the token pair.
     * @param _receiver Address of the recipient of unlocked tokens.
     * @notice It is recommended to direct the user to Sablier UI for better error handling.
     */
    function unlockLiquidityTokens(address _pair, address _receiver) external {
        if (_receiver == address(0)) {
            revert MemeFactory__ZeroAddress();
        }

        uint256 streamId = liquidityLocks[msg.sender][_pair];
        if (streamId == 0) {
            revert MemeFactory__Unauthorized();
        }

        uint256 withdrawableAmount = sablier.withdrawableAmountOf(streamId);
        if (withdrawableAmount == 0) {
            revert MemeFactory__LiquidityLockedOrDepleted();
        }

        sablier.withdrawMax({streamId: streamId, to: _receiver}); // Other reverts are handled by Sablier

        emit LiquidityTokensUnlocked(_pair, _receiver);
    }

    /**
     * @dev Transfers the locked liquidity to the specified recipient for the given pair.
     * @param _pair Address of the token pair.
     * @param _to Address of the recipient.
     */
    function transferLock(address _pair, address _to) external {
        uint256 streamId = liquidityLocks[msg.sender][_pair];
        if (
            streamId == 0 ||
            _to == address(0) ||
            sablier.isTransferable(streamId) == false
        ) {
            revert MemeFactory__Unauthorized();
        }

        liquidityLocks[_to][_pair] = streamId; /// @dev Safe to overwrite after transfer
        liquidityLocks[msg.sender][_pair] = 0; /// @dev Safe to overwrite after transfer

        sablier.transferFrom({from: msg.sender, to: _to, tokenId: streamId}); // Other reverts are handled by Sablier

        emit LiquidityTransferred(_pair, _to);
    }

    /**
     * @dev Sets the minimum liquidity for creating new tokens.
     * @param _liquidity New liquidity.
     */

    function setMinimumLiquidityETH(uint256 _liquidity) external onlyOwner {
        if (_liquidity == 0) {
            revert MemeFactory__Invalid();
        }
        minLiquidityETH = _liquidity;
        emit MinimumLiquidityETHUpdated(_liquidity);
    }

    /**
     * @dev Sets the minimum liquidity for creating new tokens.
     * @param _lockDuration New lock duration in days.
     */

    function setMinLockDuration(uint40 _lockDuration) external onlyOwner {
        if (_lockDuration == 0) {
            revert MemeFactory__Invalid();
        }
        minLockDuration = _lockDuration;
        emit MinimumLockDurationUpdated(_lockDuration);
    }

    /**
     * @dev Sets the launch fee for creating new tokens.
     * @param _launchFee New launch fee in USDC.
     */

    function setLaunchFee(uint256 _launchFee) external onlyOwner {
        if (_launchFee == 0) {
            revert MemeFactory__Invalid();
        }
        launchFee = _launchFee;
        emit LaunchFeeUpdated(_launchFee);
    }

    /**
     * @dev Sets the VaporDEX adapter address.
     * @param _vaporDexAdapter New VaporDEX adapter address.
     */

    function setVaporDEXAdapter(address _vaporDexAdapter) external onlyOwner {
        if (
            _vaporDexAdapter == vaporDexAdapter ||
            _vaporDexAdapter == address(0)
        ) {
            revert MemeFactory__Invalid();
        }
        vaporDexAdapter = _vaporDexAdapter;
        emit VaporDEXAdapterUpdated(_vaporDexAdapter);
    }

    /**
     * @dev Withdraws any remaining USDC fees to the specified address.
     * @param _to Address to which the remaining fees are withdrawn.
     */

    function withdrawFee(address _to) external onlyOwner {
        if (_to == address(0)) {
            revert MemeFactory__ZeroAddress();
        }
        IERC20 _usdc = IERC20(USDC);
        _usdc.transfer(_to, _usdc.balanceOf(address(this)));
        emit AccumulatedFeesWithdrawn(_to, _usdc.balanceOf(address(this)));
    }

    /**
     * @dev Returns the liquidity lock for the specified pair and owner.
     * @param _pair Address of the token pair.
     * @param _owner Address of the owner.
     * @return uint256 Stream ID for the liquidity lock.
     */

    function getLiquidityLock(
        address _pair,
        address _owner
    ) external view returns (uint256) {
        return liquidityLocks[_owner][_pair];
    }

    /**
     * @dev Creates a new Token contract with specified parameters.
     * @param name Name of the token.
     * @param symbol Symbol of the token.
     * @param totalSupply Total supply of the token.
     * @param _tradingStartsAt Timestamp when trading starts for the token.
     * @param dexAggregator Address of the decentralized exchange aggregator.
     * @param dexAdapter Address of the decentralized exchange adapter.
     * @return _token Instance of the created Token contract.
     */
    function _createToken(
        string memory name,
        string memory symbol,
        uint256 totalSupply,
        uint256 _tradingStartsAt,
        address dexAggregator,
        address dexAdapter
    ) internal returns (Token _token) {
        if (totalSupply == 0 || _tradingStartsAt < block.timestamp + 2 days) {
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

    /**
     * @dev Transfers the launch fee in USDC from the sender.
     * @param _from Address from which the launch fee is transferred.
     */

    function _transferLaunchFee(address _from) internal {
        IERC20 _usdc = IERC20(USDC);
        if (_usdc.balanceOf(_from) < launchFee) {
            revert MemeFactory__InsufficientBalance();
        }
        bool isSuccess = _usdc.transferFrom(_from, teamMultisig, launchFee);
        if (!isSuccess) {
            revert MemeFactory__TranferFailed(_from);
        }
    }
}
