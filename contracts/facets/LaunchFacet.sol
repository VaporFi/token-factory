// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {ILaunchFacet} from "../interfaces/ILaunchFacet.sol";
import {AppStorage, TokenLaunch} from "../libraries/LibAppStorage.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IVaporDEXFactory} from "../interfaces/IVaporDEXFactory.sol";
import {IVaporDEXRouter} from "../interfaces/IVaporDEXRouter.sol";
import {ISablierV2LockupLinear} from "@sablier/v2-core/src/interfaces/ISablierV2LockupLinear.sol";
import {LockupLinear} from "@sablier/v2-core/src/types/DataTypes.sol";
import {IERC20Token} from "../interfaces/IERC20Token.sol";
import {IDexAggregator} from "../interfaces/IDexAggregator.sol";
import {INonfungiblePositionManager} from "../interfaces/INonfungiblePositionManager.sol";
import {LibPercentages} from "../libraries/LibPercentages.sol";
import {ERC20Token} from "../tokens/ERC20Token.sol";

error LaunchFacet__NotEnoughLiquidity();
error LaunchFacet__InsufficientBalance();
error LaunchFacet__TranferFailed(address _from);
error LaunchFacet__ZeroAddress();
error LaunchFacet__MinimumLockDuration();
error LaunchFacet__WrongLaunchArguments();

contract LaunchFacet is ILaunchFacet {
    AppStorage s;

    function launchERC20(
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
        if (msg.value < s.minLiquidityETH) {
            revert LaunchFacet__NotEnoughLiquidity();
        }

        // Step 0: Transfer Fee
        _transferLaunchFee(msg.sender);

        // Step 1: Create the token
        _tokenAddress = _createToken(
            _name,
            _symbol,
            _totalSupply,
            _tradingStartsAt,
            s.VaporDEXAggregator,
            s.VaporDEXAdapter
        );
        IERC20Token _token = IERC20Token(_tokenAddress);

        // Step 2: Create the pair
        IVaporDEXFactory _factory = IVaporDEXFactory(s.VaporDEXFactory);
        _pair = _factory.createPair(_tokenAddress, address(s.WETH));
        _token.approve(s.VaporDEXRouter, _totalSupply);
        _token.approve(_pair, _totalSupply);

        // Step 3: Add Liquidity
        IVaporDEXRouter _router = IVaporDEXRouter(s.VaporDEXRouter);
        _router.addLiquidityETH{value: msg.value}(
            _tokenAddress,
            _totalSupply,
            _totalSupply,
            msg.value,
            address(this),
            block.timestamp + 10 minutes
        );

        // Step 4: Get the pair address
        _pair = _factory.getPair(_tokenAddress, address(s.WETH));
        if (_pair == address(0)) {
            revert LaunchFacet__ZeroAddress();
        }

        // Step 5: Set the LP address in the token
        _token.setLiquidityPool(_pair);
        // Step 6: Renounce ownership of the token
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
            if (lockDuration < s.minLockDuration) {
                revert LaunchFacet__MinimumLockDuration();
            }
            _lpToken.approve(
                address(s.sablier),
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
            streamId = ISablierV2LockupLinear(s.sablier).createWithDurations(
                params
            );
            s.liquidityLocks[msg.sender][_pair] = streamId;

            emit StreamCreated(streamId, msg.sender, _pair);
        }

        // Step 7: Buy VAPE with USDC on VaporDEXAggregator
        _buyVapeWithUsdc(s.launchFee / 2); // 50% of the launch fee, Admin can change launchFee but this will always be 50% of the launch fee

        // Step 8: Add Liquidity on VAPE/USDC Pair VaporDEXV2
        _addLiquidityVapeUsdc(); // Uses the balance of VAPE and USDC in the contract

        // Step 9: Store the token launch
        emit TokenLaunched(_tokenAddress, msg.sender, s.tokenLaunchesCount);

        s.tokenLaunches[s.tokenLaunchesCount] = TokenLaunch(
            _name,
            _symbol,
            _tradingStartsAt,
            streamId,
            _tokenAddress,
            _pair,
            msg.sender,
            _burnLiquidity
        );
        s.tokenLaunchesCount++;
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
    ) internal returns (address _token) {
        if (totalSupply == 0 || _tradingStartsAt < block.timestamp + 2 days) {
            revert LaunchFacet__WrongLaunchArguments();
        }
        _token = address(
            new ERC20Token(
                name,
                symbol,
                totalSupply,
                s.Stratosphere,
                address(this),
                _tradingStartsAt,
                dexAggregator,
                dexAdapter
            )
        );
    }

    /**
     * @dev Transfers the launch fee in USDC from the sender.
     * @param _from Address from which the launch fee is transferred.
     */

    function _transferLaunchFee(address _from) internal {
        IERC20 _usdc = IERC20(s.USDC);
        if (_usdc.balanceOf(_from) < s.launchFee) {
            revert LaunchFacet__InsufficientBalance();
        }
        bool isSuccess = _usdc.transferFrom(_from, address(this), s.launchFee);
        if (!isSuccess) {
            revert LaunchFacet__TranferFailed(_from);
        }
    }

    /**
     * @dev Buys VAPE with USDC on VaporDEXAggregator
     * @param amountIn Amount of USDC to be used for buying VAPE.
     */

    function _buyVapeWithUsdc(uint256 amountIn) internal {
        IERC20(s.USDC).approve(address(s.VaporDEXAggregator), amountIn);

        IDexAggregator.FormattedOffer memory offer = IDexAggregator(
            s.VaporDEXAggregator
        ).findBestPath(
                amountIn,
                address(s.USDC),
                address(s.VAPE),
                1 // can be changed to 3
            );
        IDexAggregator.Trade memory trade;
        trade.amountIn = amountIn;
        trade.amountOut = offer.amounts[offer.amounts.length - 1];
        trade.path = offer.path;
        trade.adapters = offer.adapters;
        IDexAggregator(s.VaporDEXAggregator).swapNoSplit(
            trade,
            address(this),
            0
        );
    }

    /**
     * @dev Adds liquidity for VAPE/USDC pair on VaporDEXV2.
     * @notice Uses the balance of VAPE and USDC in the contract.
     */

    function _addLiquidityVapeUsdc() internal {
        address _usdc = s.USDC;
        address _vape = s.VAPE;
        uint256 amountInUSDC = IERC20(_usdc).balanceOf(address(this));
        uint256 amountInVAPE = IERC20(_vape).balanceOf(address(this));
        IERC20(_usdc).approve(address(s.VaporDEXRouter), amountInUSDC);
        IERC20(_vape).approve(
            address(s.nonFungiblePositionManager),
            amountInVAPE
        );
        INonfungiblePositionManager.MintParams memory mintParams = INonfungiblePositionManager
            .MintParams({
                token0: _vape,
                token1: _usdc,
                fee: 3000,
                tickLower: -887220, // full range
                tickUpper: 887220, // full range
                amount0Desired: amountInVAPE,
                amount1Desired: amountInUSDC,
                amount0Min: amountInVAPE -
                    LibPercentages.percentage(amountInVAPE, s.slippage), // 2% slippage
                amount1Min: amountInUSDC -
                    LibPercentages.percentage(amountInUSDC, s.slippage), // 2% slippage
                recipient: s.teamMultisig,
                deadline: block.timestamp + 2 minutes
            });
        INonfungiblePositionManager(s.nonFungiblePositionManager).mint(
            mintParams
        );

        // Q: What checks should be done with the return values?
    }
}
