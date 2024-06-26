// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { TokenFactoryAvalancheTest, IERC20 } from "./TokenFactoryAvalanche.t.sol";
import { ERC20Token, ERC20Token__ExceedsMaximumHolding } from "../contracts/tokens/ERC20Token.sol";
import { IDexAggregator } from "../contracts/interfaces/IDexAggregator.sol";
import "forge-std/console.sol";
import { IStratosphere } from "../contracts/interfaces/IStratosphere.sol";
import { ERC20Token__NonStratosphereNFTHolder, ERC20Token__TradingNotStarted, ERC20Token__ExceedsMaximumHolding } from "../contracts/tokens/ERC20Token.sol";

contract TokenSwapTest is TokenFactoryAvalancheTest {
  ERC20Token public token;
  IERC20 public pair;
  IDexAggregator public dexAggregator = IDexAggregator(_vaporDexAggregator);
  IERC20 public WNATIVE = IERC20(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);

  function _setUp(bool _mintStrat, uint256 _tradingStartsAt) internal {
    (address _pair, address tokenAddress, ) = _launch(
      _tradingStartsAt,
      false,
      minimumLiquidityETH,
      minlockDuration + 1
    );
    token = ERC20Token(tokenAddress);
    pair = IERC20(_pair);

    if (_mintStrat) {
      _mintStratNFT();
    }
  }

  function test_Transfer() public {
    vm.startPrank(_jose);
    _setUp({ _mintStrat: true, _tradingStartsAt: block.timestamp });
    vm.stopPrank();

    vm.startPrank(_hitesh);
    _mintStratNFT();
    vm.stopPrank();

    assertTrue(token.balanceOf(_jose) == 0);
    assertTrue(token.balanceOf(_hitesh) == 0);

    vm.startPrank(address(pair));
    token.transfer(_jose, token.maxHoldingAmount());
    token.transfer(_hitesh, token.maxHoldingAmount());
    assertTrue(token.balanceOf(_jose) == token.maxHoldingAmount());
    assertTrue(token.balanceOf(_hitesh) == token.maxHoldingAmount());
    vm.stopPrank();

    vm.warp(block.timestamp + 121 minutes);
    assertTrue(token.balanceOf(_roy) == 0);
    vm.startPrank(_jose);
    token.transfer(_roy, 100 ether);
    assertTrue(token.balanceOf(_roy) == 100 ether);
    assertTrue(token.balanceOf(_jose) == token.maxHoldingAmount() - 100 ether);
    vm.stopPrank();

    vm.startPrank(_roy);
    token.transfer(_hitesh, 100 ether);
    assertTrue(token.balanceOf(_hitesh) == token.maxHoldingAmount() + 100 ether);
    assertTrue(token.balanceOf(_roy) == 0);
    vm.stopPrank();
  }

  function test_Revert_Transfer_AntiWhaleLimit() public {
    vm.startPrank(_jose);
    _setUp({ _mintStrat: true, _tradingStartsAt: block.timestamp });
    vm.stopPrank();

    vm.startPrank(_hitesh);
    _mintStratNFT();
    vm.stopPrank();

    assertTrue(token.balanceOf(_jose) == 0);
    assertTrue(token.balanceOf(_hitesh) == 0);

    vm.startPrank(address(pair));
    token.transfer(_jose, token.maxHoldingAmount());
    token.transfer(_hitesh, token.maxHoldingAmount());
    assertTrue(token.balanceOf(_jose) == token.maxHoldingAmount());
    assertTrue(token.balanceOf(_hitesh) == token.maxHoldingAmount());

    vm.expectRevert(ERC20Token__ExceedsMaximumHolding.selector);
    token.transfer(_jose, 1);
    vm.stopPrank();

    vm.startPrank(_jose);
    vm.expectRevert(ERC20Token__ExceedsMaximumHolding.selector);
    token.transfer(_hitesh, 1);
    vm.stopPrank();

    vm.warp(block.timestamp + 3 hours);
    vm.startPrank(_jose);
    token.transfer(_hitesh, 100 ether);
    assertTrue(token.balanceOf(_hitesh) == token.maxHoldingAmount() + 100 ether);
    assertTrue(token.balanceOf(_jose) == token.maxHoldingAmount() - 100 ether);
    vm.stopPrank();
  }

  function test_FindBestPath_IncludesVaporDEXAdapter() public {
    vm.startPrank(_user);
    _setUp({ _mintStrat: false, _tradingStartsAt: block.timestamp });
    uint256 amountIn = 1 * 1e16;
    address tokenIn = address(token);
    address tokenOut = address(WNATIVE);
    uint256 maxSteps = 1;
    IDexAggregator.FormattedOffer memory offer = dexAggregator.findBestPath(amountIn, tokenIn, tokenOut, maxSteps);
    assertTrue(offer.amounts[offer.amounts.length - 1] > 0, "No amounts found");
    assertTrue(offer.adapters.length > 0, "No adapters found");
    address adapter = offer.adapters[offer.adapters.length - 1];
    assertTrue(adapter == _vaporDexAdapter, "VaporDEX adapter not found");
    address tokenOutOffer = offer.path[offer.path.length - 1];
    assertTrue(tokenOutOffer == address(WNATIVE), "WNATIVE not found");
    vm.stopPrank();
  }

  function test_SwapNoSplitFromAVAX_StratMember_TradingStarted() public {
    vm.startPrank(_jose);
    _setUp({ _mintStrat: true, _tradingStartsAt: block.timestamp });
    uint256 amountIn = 1 * 1e16;
    address tokenIn = address(WNATIVE);
    address tokenOut = address(token);
    uint256 maxSteps = 1;
    IDexAggregator.FormattedOffer memory offer = dexAggregator.findBestPath(amountIn, tokenIn, tokenOut, maxSteps);
    IDexAggregator.Trade memory trade;
    trade.amountIn = amountIn;
    trade.amountOut = offer.amounts[offer.amounts.length - 1];
    trade.path = offer.path;
    trade.adapters = offer.adapters;
    assertTrue(token.balanceOf(address(_jose)) == 0, "Balance not 0");
    dexAggregator.swapNoSplitFromAVAX{ value: amountIn }(trade, address(_jose), 0);
    assertTrue(token.balanceOf(address(_jose)) == trade.amountOut, "AmountOut not received");

    // Selling token for AVAX
    amountIn = trade.amountOut;
    tokenIn = address(token);
    tokenOut = address(WNATIVE);
    offer = dexAggregator.findBestPath(amountIn, tokenIn, tokenOut, maxSteps);
    trade.amountIn = amountIn;
    trade.amountOut = offer.amounts[offer.amounts.length - 1];
    trade.path = offer.path;
    trade.adapters = offer.adapters;
    uint256 avaxBalanceBefore = address(_jose).balance;
    token.approve(address(dexAggregator), trade.amountIn);
    dexAggregator.swapNoSplitToAVAX(trade, address(_jose), 0);
    assertTrue(token.balanceOf(address(_jose)) == 0, "Balance not 0");
    assertTrue(address(_jose).balance > avaxBalanceBefore, "AVAX not received");
    console.log("AVAX received: ", address(_jose).balance - avaxBalanceBefore);
    vm.stopPrank();
  }

  function test_TradingStarted_LessThan2Hours_NonStratMember() public {
    vm.startPrank(_user);
    _setUp({ _mintStrat: false, _tradingStartsAt: block.timestamp });
    uint256 amountIn = 1 * 1e16;
    address tokenIn = address(WNATIVE);
    address tokenOut = address(token);
    uint256 maxSteps = 1;
    IDexAggregator.FormattedOffer memory offer = dexAggregator.findBestPath(amountIn, tokenIn, tokenOut, maxSteps);
    IDexAggregator.Trade memory trade;
    trade.amountIn = amountIn;
    trade.amountOut = offer.amounts[offer.amounts.length - 1];
    trade.path = offer.path;
    trade.adapters = offer.adapters;
    vm.warp(block.timestamp + 1 hours);
    assertTrue(token.balanceOf(address(_jose)) == 0, "Balance not 0");
    dexAggregator.swapNoSplitFromAVAX{ value: amountIn }(trade, address(_jose), 0);
    assertTrue(token.balanceOf(address(_jose)) == trade.amountOut, "AmountOut not received");
    vm.stopPrank();
  }

  function test_Revert_SwapNoSplitFromAVAX_StratMember_TradingNotStarted() public {
    vm.startPrank(_jose);
    _setUp({ _mintStrat: true, _tradingStartsAt: block.timestamp + 2 days });
    uint256 amountIn = 1 * 1e16;
    address tokenIn = address(WNATIVE);
    address tokenOut = address(token);
    uint256 maxSteps = 1;
    IDexAggregator.FormattedOffer memory offer = dexAggregator.findBestPath(amountIn, tokenIn, tokenOut, maxSteps);
    IDexAggregator.Trade memory trade;
    trade.amountIn = amountIn;
    trade.amountOut = offer.amounts[offer.amounts.length - 1];
    trade.path = offer.path;
    trade.adapters = offer.adapters;
    vm.expectRevert("VaporDEX: TRANSFER_FAILED");
    dexAggregator.swapNoSplitFromAVAX{ value: amountIn }(trade, address(_jose), 0);
    vm.stopPrank();
  }

  function test_Revert_SwapNoSplitFromAVAX_NonStratMember_TradingStarted() public {
    vm.startPrank(_jose);
    _setUp({ _mintStrat: false, _tradingStartsAt: block.timestamp });
    uint256 amountIn = 1 * 1e16;
    address tokenIn = address(WNATIVE);
    address tokenOut = address(token);
    uint256 maxSteps = 1;
    IDexAggregator.FormattedOffer memory offer = dexAggregator.findBestPath(amountIn, tokenIn, tokenOut, maxSteps);
    IDexAggregator.Trade memory trade;
    trade.amountIn = amountIn;
    trade.amountOut = offer.amounts[offer.amounts.length - 1];
    trade.path = offer.path;
    trade.adapters = offer.adapters;
    assertTrue(token.balanceOf(address(_jose)) == 0, "Balance not 0");
    vm.expectRevert("VaporDEX: TRANSFER_FAILED");
    dexAggregator.swapNoSplitFromAVAX{ value: amountIn }(trade, address(_jose), 0);
    vm.stopPrank();
  }

  function test_Revert_AntiWhale_ExceedsMaximumHolding() public {
    vm.startPrank(_jose);
    _setUp({ _mintStrat: true, _tradingStartsAt: block.timestamp });
    uint256 amountIn = 1000 ether;
    address tokenIn = address(WNATIVE);
    address tokenOut = address(token);
    uint256 maxSteps = 1;
    IDexAggregator.FormattedOffer memory offer = dexAggregator.findBestPath(amountIn, tokenIn, tokenOut, maxSteps);
    IDexAggregator.Trade memory trade;
    trade.amountIn = amountIn;
    trade.amountOut = offer.amounts[offer.amounts.length - 1];
    trade.path = offer.path;
    trade.adapters = offer.adapters;
    assertTrue(token.balanceOf(address(_jose)) == 0, "Balance not 0");
    vm.expectRevert("VaporDEX: TRANSFER_FAILED");
    dexAggregator.swapNoSplitFromAVAX{ value: amountIn }(trade, address(_jose), 0);
    vm.stopPrank();
  }

  function test_Revert_AntiWhale_ExceedsMaximumHolding_TradingStarted_LessThan2Hours_NonStratMember() public {
    vm.startPrank(_user);
    _setUp({ _mintStrat: false, _tradingStartsAt: block.timestamp });
    uint256 amountIn = 1000 ether;
    address tokenIn = address(WNATIVE);
    address tokenOut = address(token);
    uint256 maxSteps = 1;
    IDexAggregator.FormattedOffer memory offer = dexAggregator.findBestPath(amountIn, tokenIn, tokenOut, maxSteps);
    IDexAggregator.Trade memory trade;
    trade.amountIn = amountIn;
    trade.amountOut = offer.amounts[offer.amounts.length - 1];
    trade.path = offer.path;
    trade.adapters = offer.adapters;
    vm.warp(block.timestamp + 1 hours);
    assertTrue(token.balanceOf(address(_jose)) == 0, "Balance not 0");
    vm.expectRevert("VaporDEX: TRANSFER_FAILED");
    dexAggregator.swapNoSplitFromAVAX{ value: amountIn }(trade, address(_jose), 0);
    vm.stopPrank();
  }

  function test_MultiSwaps_TradingStarted_MoreThan2Hours() public {
    vm.startPrank(_jose);
    _setUp({ _mintStrat: true, _tradingStartsAt: block.timestamp + 2 days });
    vm.stopPrank();

    // Buying token with AVAX
    uint256 amountIn = 1 * 1e16;
    address tokenIn = address(WNATIVE);
    address tokenOut = address(token);
    uint256 maxSteps = 1;

    vm.warp(block.timestamp + 2 days + 61 minutes);

    vm.startPrank(_user);
    IDexAggregator.FormattedOffer memory offer = dexAggregator.findBestPath(amountIn, tokenIn, tokenOut, maxSteps);
    IDexAggregator.Trade memory trade;
    trade.amountIn = amountIn;
    trade.amountOut = offer.amounts[offer.amounts.length - 1];
    trade.path = offer.path;
    trade.adapters = offer.adapters;
    assertTrue(token.balanceOf(address(_user)) == 0, "Balance not 0");
    dexAggregator.swapNoSplitFromAVAX{ value: amountIn }(trade, address(_user), 0);
    assertTrue(token.balanceOf(address(_user)) == trade.amountOut, "AmountOut not received");
    vm.stopPrank();

    vm.startPrank(_jose);
    offer = dexAggregator.findBestPath(amountIn, tokenIn, tokenOut, maxSteps);
    trade.amountIn = amountIn;
    trade.amountOut = offer.amounts[offer.amounts.length - 1];
    trade.path = offer.path;
    trade.adapters = offer.adapters;
    assertTrue(token.balanceOf(address(_jose)) == 0, "Balance not 0");
    dexAggregator.swapNoSplitFromAVAX{ value: amountIn }(trade, address(_jose), 0);
    assertTrue(token.balanceOf(address(_jose)) == trade.amountOut, "AmountOut not received");
    vm.stopPrank();

    vm.startPrank(_hitesh);
    offer = dexAggregator.findBestPath(amountIn, tokenIn, tokenOut, maxSteps);
    trade.amountIn = amountIn;
    trade.amountOut = offer.amounts[offer.amounts.length - 1];
    trade.path = offer.path;
    trade.adapters = offer.adapters;
    assertTrue(token.balanceOf(address(_hitesh)) == 0, "Balance not 0");
    dexAggregator.swapNoSplitFromAVAX{ value: amountIn }(trade, address(_hitesh), 0);
    assertTrue(token.balanceOf(address(_hitesh)) == trade.amountOut, "AmountOut not received");

    // Selling token for AVAX as Hitesh
    amountIn = trade.amountOut;
    tokenIn = address(token);
    tokenOut = address(WNATIVE);
    offer = dexAggregator.findBestPath(amountIn, tokenIn, tokenOut, maxSteps);
    trade.amountIn = amountIn;
    trade.amountOut = offer.amounts[offer.amounts.length - 1];
    trade.path = offer.path;
    trade.adapters = offer.adapters;
    uint256 avaxBalanceBefore = address(_hitesh).balance;
    token.approve(address(dexAggregator), trade.amountIn);
    dexAggregator.swapNoSplitToAVAX(trade, address(_hitesh), 0);
    assertTrue(token.balanceOf(address(_hitesh)) == 0, "Balance not 0");
    assertTrue(address(_hitesh).balance > avaxBalanceBefore, "AVAX not received");
    console.log("AVAX received: ", address(_hitesh).balance - avaxBalanceBefore);
    vm.stopPrank();

    vm.startPrank(_user);
    amountIn = token.balanceOf(address(_user));
    offer = dexAggregator.findBestPath(amountIn, tokenIn, tokenOut, maxSteps);
    trade.amountIn = amountIn;
    trade.amountOut = offer.amounts[offer.amounts.length - 1];
    trade.path = offer.path;
    trade.adapters = offer.adapters;
    avaxBalanceBefore = address(_user).balance;
    token.approve(address(dexAggregator), trade.amountIn);
    dexAggregator.swapNoSplitToAVAX(trade, address(_user), 0);
    assertTrue(token.balanceOf(address(_user)) == 0, "Balance not 0");
    assertTrue(address(_user).balance > avaxBalanceBefore, "AVAX not received");
    console.log("AVAX received: ", address(_user).balance - avaxBalanceBefore);
    vm.stopPrank();
  }

  function _mintStratNFT() internal {
    IStratosphere stratosphere = IStratosphere(_stratosphere);
    stratosphere.mint();
  }
}
