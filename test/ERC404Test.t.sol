// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { ERC404ExampleVaporDexV1 } from "./examples/ERC404ExampleVaporDexV1.sol";
import { IUniswapV2Pair } from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import { IUniswapV2Router02 } from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import { Test } from "forge-std/Test.sol";
import { ERC20Mock } from "./mocks/ERC20Mock.sol";
import { IDexAggregator } from "../contracts/interfaces/IDexAggregator.sol";
import {console} from "forge-std/console.sol";

contract ERC404Test is Test {
  ERC404ExampleVaporDexV1 public erc404ExampleVaporDexV1;
  IUniswapV2Pair public uniswapV2Pair = IUniswapV2Pair(0xf9C38f31c7DC629ea3B9c7C3f57a0938b7cD4721); // Predetermined pair address
  IUniswapV2Router02 public uniswapV2Router = IUniswapV2Router02(0x19C0FC4562A4b76F27f86c676eF5a7e38D12a20d); 
  ERC20Mock public mockERC20;
  IDexAggregator public dexAggregator = IDexAggregator(0x55477d8537ede381784b448876AfAa98aa450E63);
  address user = makeAddr("user");

  function setUp() public {
    vm.createSelectFork("https://api.avax.network/ext/bc/C/rpc");

    erc404ExampleVaporDexV1 = new ERC404ExampleVaporDexV1(
      "ERC404Mock",
      "ERC404Mock",
      18,
      1000,
      address(this),
      address(this),
      address(uniswapV2Router)
    );

    mockERC20 = new ERC20Mock("MockERC20", "MRC20");
    mockERC20.mint(address(this), 1000 ether);
    mockERC20.mint(user, 1000 ether);
  }

  function test_setUp() public {
    assertEq(erc404ExampleVaporDexV1.name(), "ERC404Mock");
    assertEq(erc404ExampleVaporDexV1.symbol(), "ERC404Mock");
    assertEq(erc404ExampleVaporDexV1.decimals(), 18);
  }

  function _createLiquidity() internal {
    vm.startPrank(address(this));
    mockERC20.approve(address(uniswapV2Router), 1000 ether);
    erc404ExampleVaporDexV1.approve(address(uniswapV2Router), 1000 ether);
    uniswapV2Router.addLiquidity(
      address(erc404ExampleVaporDexV1),
      address(mockERC20),
      1000 ether,
      1000 ether,
      1000 ether,
      1000 ether,
      address(this),
      block.timestamp
    );

    vm.stopPrank();
  }

  function test_Swap() public {
    _createLiquidity();
    vm.startPrank(user);
    mockERC20.approve(address(dexAggregator), 1e16);
    uint256 amountIn = 1e16;
    address tokenIn = address(mockERC20);
    address tokenOut = address(erc404ExampleVaporDexV1);
    uint256 maxSteps = 1;
    IDexAggregator.FormattedOffer memory offer = dexAggregator.findBestPath(amountIn, tokenIn, tokenOut, maxSteps);
    IDexAggregator.Trade memory trade;
    trade.amountIn = amountIn;
    trade.amountOut = offer.amounts[offer.amounts.length - 1];
    trade.path = offer.path;
    trade.adapters = offer.adapters;
    uint256 balance = erc404ExampleVaporDexV1.balanceOf(user);
    assertEq(balance, 0);
    console.log("Balance of user before swap: ", balance);
    dexAggregator.swapNoSplit(trade, user, 0);
    balance = erc404ExampleVaporDexV1.balanceOf(user);
    console.log("Balance of user after swap: ", balance);
    assertEq(balance, trade.amountOut);
    assert(balance > 0);
    vm.stopPrank();
  }

}
