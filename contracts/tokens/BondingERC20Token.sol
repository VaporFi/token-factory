// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {ERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Factory} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

error NeedToSendETH();
error NeedToSellTokens();
error ContractNotEnoughETH();
error FailedToSendETH();

contract BondingERC20Token is ERC20, Ownable, ReentrancyGuard {
    IUniswapV2Router02 public immutable router;
    IUniswapV2Factory public immutable factory;
    address public immutable WETH;
    address public constant BURN_ADDRESS =
        0x000000000000000000000000000000000000dEaD;
    address public immutable marketing;
    address public immutable treasury;
    uint public constant INITIAL_PRICE = 1e12; // Initial price per token
    uint public constant PRICE_FACTOR = 1e6; // Price factor for logarithmic curve
    uint public totalETHContributed;
    uint public liquidityGoal = 10 ether;

    constructor(
        address _owner,
        address _router,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) Ownable(_owner) {
        router = IUniswapV2Router02(_router);
        factory = IUniswapV2Factory(router.factory());
        WETH = router.WETH();
    }

    function buyTokens() external payable {
        if (msg.value == 0) revert NeedToSendETH();
        uint tokensToBuy = calculateTokenAmount(msg.value);
        _mint(msg.sender, tokensToBuy);
        totalETHContributed += msg.value;
        if (totalETHContributed >= liquidityGoal) {
            createPair();
        }
    }

    function sellTokens(uint tokenAmount) external nonReentrant {
        if (tokenAmount == 0) revert NeedToSellTokens();
        uint ethAmount = calculateETHAmount(tokenAmount);
        if (address(this).balance < ethAmount) revert ContractNotEnoughETH();

        _burn(msg.sender, tokenAmount);
        (bool sent, ) = msg.sender.call{value: ethAmount}("");
        if (!sent) revert FailedToSendETH();
    }

    function calculateTokenAmount(uint ethAmount) public view returns (uint) {
        uint currentSupply = totalSupply();
        // Logarithmic bonding curve: price = INITIAL_PRICE * (1 + log(1 + currentSupply / PRICE_FACTOR))
        uint pricePerToken = (INITIAL_PRICE *
            (1e18 + log(1e18 + (currentSupply * 1e18) / PRICE_FACTOR))) / 1e18;
        return (ethAmount * 1e18) / pricePerToken;
    }

    function calculateETHAmount(uint tokenAmount) public view returns (uint) {
        uint currentSupply = totalSupply();
        // Assuming you want to use the same price calculation for selling,
        // but you might want to adjust this for sell pricing
        uint pricePerToken = (INITIAL_PRICE *
            (1e18 + log(1e18 + (currentSupply * 1e18) / PRICE_FACTOR))) / 1e18;
        return (tokenAmount * pricePerToken) / 1e18;
    }

    function createPair() internal {
        uint ethAmount = address(this).balance;
        uint tokenAmount = this.balanceOf(address(this));
        _approve(address(this), address(router), tokenAmount);

        // Add liquidity
        (, , uint liquidity) = router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            tokenAmount,
            ethAmount,
            address(this),
            block.timestamp
        );

        // Burn the LP tokens received
        IERC20 lpToken = IERC20(factory.getPair(address(this), WETH));
        lpToken.transfer(BURN_ADDRESS, liquidity);
    }

    function log(uint x) internal pure returns (uint) {
        uint res = 0;
        while (x >= 1e18) {
            x /= 1e18;
            res += 1e18;
        }
        return res;
    }

    receive() external payable {}
}
