// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/console.sol";
import {LaunchERC20Facet} from "contracts/facets/LaunchERC20Facet.sol";
import {AdminFacet} from "contracts/facets/AdminFacet.sol";
import {Test} from "forge-std/Test.sol";
import {IDexAggregator} from "../contracts/interfaces/IDexAggregator.sol";
import "forge-std/console.sol";
import {IStratosphere} from "../contracts/interfaces/IStratosphere.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Simulate is Test {
    LaunchERC20Facet public launchERC20Facet;
    AdminFacet public adminFacet;
    address public token = 0xb3298f3fB530223Fc714EcA85cdEdc6F66E12D73;
    address public pair = 0x8265D6aCFa07359E4eA713CECDEbC76beFaCB6BB;
    address public WNATIVE = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    IDexAggregator public dexAggregator =
        IDexAggregator(0x55477d8537ede381784b448876AfAa98aa450E63);
    IStratosphere public stratosphere =
        IStratosphere(0x08e287adCf9BF6773a87e1a278aa9042BEF44b60);

    function setUp() public {
        vm.createSelectFork("https://api.avax.network/ext/bc/C/rpc");
        vm.deal(0x6f9A40734c3a7CE5Eef399ce22D6160a4A193Ca5, 1 ether);
    }

    function test_R_LaunchERC20() public {
        vm.startPrank(0x6f9A40734c3a7CE5Eef399ce22D6160a4A193Ca5);
        uint256 balance = IERC20(token).balanceOf(
            0x6f9A40734c3a7CE5Eef399ce22D6160a4A193Ca5
        );
        vm.deal(0x6f9A40734c3a7CE5Eef399ce22D6160a4A193Ca5, 2 ether);
        uint256 amountIn = 1.2 ether;
        address tokenIn = WNATIVE;
        address tokenOut = token;
        uint256 maxSteps = 1;
        IDexAggregator.FormattedOffer memory offer = dexAggregator.findBestPath(
            amountIn,
            tokenIn,
            tokenOut,
            maxSteps
        );
        IDexAggregator.Trade memory trade;
        trade.amountIn = amountIn;
        trade.amountOut = offer.amounts[offer.amounts.length - 1];
        uint256 newbalance = balance + trade.amountOut;
        console.log(newbalance / 1e18);
        trade.path = offer.path;
        trade.adapters = offer.adapters;
        dexAggregator.swapNoSplitFromAVAX{value: amountIn}(
            trade,
            0x6f9A40734c3a7CE5Eef399ce22D6160a4A193Ca5,
            0
        );
        uint256 balance1 = IERC20(token).balanceOf(
            0x6f9A40734c3a7CE5Eef399ce22D6160a4A193Ca5
        );
        console.log(balance1 / 1e18);
        vm.stopPrank();
    }

    function test_transfer() public {
        vm.startPrank(0x6f9A40734c3a7CE5Eef399ce22D6160a4A193Ca5);
        IERC20(token).transfer(
            0xB6E87d208c8bF543ca5AeDC452A7eAfe442faE10,
            IERC20(token).balanceOf(0x6f9A40734c3a7CE5Eef399ce22D6160a4A193Ca5)
        );
        uint256 balance = IERC20(token).balanceOf(
            0xB6E87d208c8bF543ca5AeDC452A7eAfe442faE10
        );
        console.log(balance / 1e18);
        vm.stopPrank();
    }
}
