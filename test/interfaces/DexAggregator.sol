// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;


interface DexAggregator {

 struct FormattedOffer {
        uint256[] amounts;
        address[] adapters;
        address[] path;
        uint256 gasEstimate;
    }

struct Trade {
        uint256 amountIn;
        uint256 amountOut;
        address[] path;
        address[] adapters;
    }

function findBestPath(
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut,
        uint256 _maxSteps
    ) external view returns (FormattedOffer memory);

function swapNoSplitFromAVAX(Trade calldata _trade, address _to, uint256 _fee) external payable;

function swapNoSplitToAVAX(Trade calldata _trade, address _to, uint256 _fee) external;

function swapNoSplit(Trade calldata _trade, address _to, uint256 _fee) external;

}