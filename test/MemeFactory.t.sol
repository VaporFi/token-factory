// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Test.sol";
import "contracts/MemeFactory.sol";
import {ISablierV2LockupLinear} from "@sablier/v2-core/src/interfaces/ISablierV2LockupLinear.sol";
import {LockupLinear} from "@sablier/v2-core/src/types/DataTypes.sol";
import {ERC20Mock} from "./mocks/ERC20Mock.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MemeFactoryTest is Test {
    MemeFactory memeFactory;
    address _owner = makeAddr("owner");
    address _router = 0x19C0FC4562A4b76F27f86c676eF5a7e38D12a20d;
    address _stratosphere = 0x65eB37AeB1F2a9cE39556F80044607dD969b0336;
    address _vaporDexAggregator = 0x55477d8537ede381784b448876AfAa98aa450E63;
    address _vaporDexAdapter = 0x01e5C45cB25E30860c2Fb80369A9C27628911a2b;
    ERC20Mock _usdc;
    uint256 launchFee = 250 * 1e18;
    ISablierV2LockupLinear sablier =
        ISablierV2LockupLinear(0xB24B65E015620455bB41deAAd4e1902f1Be9805f);
    address _user = makeAddr("user");
    address _joe = makeAddr("joe");
    address _alice = makeAddr("alice");
    uint256 minimumLiquidity = 10 ** 3; // https://github.com/VaporFi/vapordex-contracts/blob/staging/contracts/VaporDEX/VaporDEXPair.sol#L21

    function setUp() public {
        vm.createSelectFork("https://api.avax.network/ext/bc/C/rpc");
        _usdc = new ERC20Mock("USDC", "USDC"); // 18 Decimals
        vm.deal(_user, 100 ether);
        vm.startPrank(_owner);
        memeFactory = new MemeFactory(
            _owner,
            _router,
            _stratosphere,
            _vaporDexAggregator,
            _vaporDexAdapter,
            address(_usdc),
            launchFee,
            address(sablier)
        );
        vm.stopPrank();
    }

    function test_LaunchWithLPBurn() public {
        vm.startPrank(_user);
        (address _pair, address _tokenAddress, uint256 streamId) = _launch(
            block.timestamp + 1 days,
            true
        );
        assertTrue(_pair != address(0), "Pair address is zero");
        assertTrue(_tokenAddress != address(0), "Token address is zero");
        assertEq(_usdc.balanceOf(address(memeFactory)), launchFee);
        assertTrue(IERC20(_pair).balanceOf(address(0)) > minimumLiquidity);
        assertTrue(streamId == 0);
        vm.stopPrank();
    }

    function test_LaunchWithLPLock() public {
        vm.startPrank(_user);
        (address _pair, address _tokenAddress, uint256 _streamId) = _launch(
            block.timestamp + 1 days,
            false
        );
        assertTrue(_pair != address(0), "Pair address is zero");
        assertTrue(_tokenAddress != address(0), "Token address is zero");
        assertEq(_usdc.balanceOf(address(memeFactory)), launchFee);
        assertTrue(IERC20(_pair).balanceOf(address(0)) == minimumLiquidity);
        assertTrue(_streamId > 0);
        vm.stopPrank();
    }

    function test_LPUnlock() public {
        vm.startPrank(_user);
        (address _pair, address _tokenAddress, uint256 _streamId) = _launch(
            block.timestamp + 1 days,
            false
        );
        assertTrue(_pair != address(0), "Pair address is zero");
        assertTrue(_tokenAddress != address(0), "Token address is zero");
        assertEq(_usdc.balanceOf(address(memeFactory)), launchFee);
        assertTrue(IERC20(_pair).balanceOf(address(0)) == minimumLiquidity);
        assertTrue(_streamId > 0);

        vm.warp(1 days);

        assertTrue(IERC20(_pair).balanceOf(address(_user)) == 0);
        uint256 withdrawalAmount = sablier.withdrawableAmountOf(_streamId);
        console.log("withdrawalAmount", withdrawalAmount);
        // memeFactory.unlockLiquidityTokens(_pair, address(memeFactory));
        // assertTrue(IERC20(_pair).balanceOf(address(_user)) > 0);
        vm.stopPrank();
    }

    function _launch(
        uint256 _releaseTime,
        bool lpBurn
    ) internal returns (address pair, address tokenAddress, uint256 streamId) {
        _usdc.mint(address(_user), launchFee);
        _usdc.approve(address(memeFactory), launchFee);

        (address _pair, address _tokenAddress, uint256 _streamId) = memeFactory
            .launch{value: 10 ether}(
            "Test Token",
            "TEST",
            1_000_000 ether,
            _releaseTime,
            lpBurn
        );

        pair = _pair;
        tokenAddress = _tokenAddress;
        streamId = _streamId;
    }
}
