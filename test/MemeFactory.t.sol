// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Test.sol";
import "contracts/MemeFactory.sol";
import {ISablierV2LockupLinear} from "@sablier/v2-core/src/interfaces/ISablierV2LockupLinear.sol";
import {LockupLinear} from "@sablier/v2-core/src/types/DataTypes.sol";
import {ERC20Mock} from "./mocks/ERC20Mock.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {LockupLinear} from "@sablier/v2-core/src/types/DataTypes.sol";

contract MemeFactoryTest is Test {
    MemeFactory memeFactory;
    address _owner = makeAddr("owner");
    address teamMultisig = makeAddr("msig");
    address _router = 0x19C0FC4562A4b76F27f86c676eF5a7e38D12a20d;
    address _stratosphere = 0x08e287adCf9BF6773a87e1a278aa9042BEF44b60;
    address _vaporDexAggregator = 0x55477d8537ede381784b448876AfAa98aa450E63;
    address _vaporDexAdapter = 0x01e5C45cB25E30860c2Fb80369A9C27628911a2b;
    ERC20Mock _usdc;
    uint256 launchFee = 250 * 1e18;
    ISablierV2LockupLinear sablier =
        ISablierV2LockupLinear(0xB24B65E015620455bB41deAAd4e1902f1Be9805f);
    address _user = makeAddr("user");
    address _jose = makeAddr("jose");
    address _hitesh = makeAddr("hitesh");
    address _roy = makeAddr("roy");
    uint256 minimumLiquidity = 10 ** 3; // https://github.com/VaporFi/vapordex-contracts/blob/staging/contracts/VaporDEX/VaporDEXPair.sol#L21
    uint256 minimumLiquidityETH = 10 ether; // to create token
    uint40 minlockDuration = 90; // 3 months

    function setUp() public {
        vm.createSelectFork("https://api.avax.network/ext/bc/C/rpc");
        _usdc = new ERC20Mock("USDC", "USDC"); // 18 Decimals
        _usdc.mint(address(_user), 100000000 ether);
        _usdc.mint(address(_jose), 100000000 ether);
        _usdc.mint(address(_hitesh), 100000000 ether);
        _usdc.mint(address(_roy), 100000000 ether);
        vm.deal(_user, 10000000 ether);
        vm.deal(_jose, 10000000 ether);
        vm.deal(_hitesh, 10000000 ether);
        vm.deal(_roy, 10000000 ether);
        vm.startPrank(_owner);
        memeFactory = new MemeFactory(
            _owner,
            _router,
            _stratosphere,
            _vaporDexAggregator,
            _vaporDexAdapter,
            teamMultisig,
            address(_usdc),
            launchFee,
            minimumLiquidityETH,
            minlockDuration,
            address(sablier)
        );
        vm.stopPrank();
    }

    function test_MinimumLiquidityETH() public {
        vm.startPrank(_user);

        _launch(block.timestamp + 2 days, true, 11 ether, minlockDuration + 1);

        vm.stopPrank();
    }

    function test_Revert_MinimumLiquidityETH() public {
        vm.startPrank(_user);

        vm.expectRevert();
        _launch(block.timestamp + 2 days, true, 9 ether, minlockDuration + 1);

        vm.stopPrank();
    }

    function test_Revert_SetMinimumLiquidityETH() public {
        vm.startPrank(_user);
        vm.expectRevert();
        memeFactory.setMinimumLiquidityETH(3 ether);
        vm.stopPrank();
    }

    function test_Revert_SetMinimumLockDuration() public {
        vm.startPrank(_user);
        vm.expectRevert();
        memeFactory.setMinLockDuration(30);
        vm.stopPrank();
    }

    function test_LaunchWithLPBurn() public {
        vm.startPrank(_user);
        (address _pair, address _tokenAddress, uint256 _streamId) = _launch(
            block.timestamp + 2 days,
            true,
            minimumLiquidityETH,
            minlockDuration + 1
        );

        // Pair and Token Checks
        assertTrue(_pair != address(0), "Pair address is zero");
        assertTrue(_tokenAddress != address(0), "Token address is zero");
        assertEq(_usdc.balanceOf(address(memeFactory)), launchFee);
        assertTrue(IERC20(_pair).balanceOf(address(0)) > minimumLiquidity);

        // Stream Checks
        assertTrue(_streamId == 0);

        vm.stopPrank();
    }

    function test_Revert_LaunchWithLPLock() public {
        vm.startPrank(_user);
        vm.expectRevert();
        _launch(
            block.timestamp + 2 days,
            false,
            minimumLiquidityETH,
            minlockDuration - 1
        );

        vm.stopPrank();
    }

    function test_LaunchWithLPLock() public {
        vm.startPrank(_user);
        (address _pair, address _tokenAddress, uint256 _streamId) = _launch(
            block.timestamp + 2 days,
            false,
            minimumLiquidityETH,
            minlockDuration + 1
        );

        // Pair and Token Checks
        assertTrue(_pair != address(0), "Pair address is zero");
        assertTrue(_tokenAddress != address(0), "Token address is zero");
        assertEq(_usdc.balanceOf(address(memeFactory)), launchFee);
        assertTrue(IERC20(_pair).balanceOf(address(0)) == minimumLiquidity);

        // Stream Checks
        assertTrue(_streamId > 0);

        LockupLinear.Stream memory stream = sablier.getStream(_streamId);
        assertEq(stream.endTime, block.timestamp + 365 days);
        assertEq(stream.isTransferable, true);
        assertEq(stream.isCancelable, false);

        address ownerOfStream = sablier.ownerOf(_streamId);
        assertTrue(ownerOfStream == _user);

        vm.stopPrank();
    }

    function test_LPUnlock() public {
        vm.startPrank(_user);
        (address _pair, , uint256 _streamId) = _launch(
            block.timestamp + 2 days,
            false,
            minimumLiquidityETH,
            minlockDuration + 1
        );

        // Before Warp
        LockupLinear.Stream memory stream = sablier.getStream(_streamId);
        assertTrue(IERC20(_pair).balanceOf(address(_user)) == 0);
        assertEq(stream.isDepleted, false);
        assertTrue(stream.amounts.withdrawn == 0);
        assertTrue(sablier.withdrawableAmountOf(_streamId) == 0);

        vm.warp(block.timestamp + 365 days);

        // After Warp
        uint256 withdrawableAmount = sablier.withdrawableAmountOf(_streamId);
        assertTrue(withdrawableAmount > 0);

        memeFactory.unlockLiquidityTokens(_pair, address(_user));
        assertTrue(
            IERC20(_pair).balanceOf(address(_user)) == withdrawableAmount
        );

        stream = sablier.getStream(_streamId);

        assertEq(stream.isDepleted, true);
        assertTrue(stream.amounts.withdrawn == withdrawableAmount);
        withdrawableAmount = sablier.withdrawableAmountOf(_streamId);
        assertTrue(withdrawableAmount == 0);

        vm.stopPrank();
    }

    function test_LPTransfer_BeforeUnlock() public {
        vm.startPrank(_user);
        (address _pair, , uint256 _streamId) = _launch(
            block.timestamp + 2 days,
            false,
            minimumLiquidityETH,
            minlockDuration + 1
        );

        LockupLinear.Stream memory stream = sablier.getStream(_streamId);
        assertTrue(IERC20(_pair).balanceOf(address(_user)) == 0);
        assertEq(stream.isDepleted, false);
        assertTrue(stream.amounts.withdrawn == 0);
        assertTrue(sablier.withdrawableAmountOf(_streamId) == 0);

        sablier.approve(address(memeFactory), _streamId);
        memeFactory.transferLock(_pair, address(_jose));
        address ownerOfStream = sablier.ownerOf(_streamId);
        assertTrue(ownerOfStream == address(_jose));

        stream = sablier.getStream(_streamId);
        assertEq(stream.isDepleted, false);
        assertTrue(stream.amounts.withdrawn == 0);
        assertTrue(sablier.withdrawableAmountOf(_streamId) == 0);

        vm.stopPrank();
    }

    function test_LPTransfer_AfterUnlock() public {
        vm.startPrank(_user);
        (address _pair, , uint256 _streamId) = _launch(
            block.timestamp + 2 days,
            false,
            minimumLiquidityETH,
            minlockDuration + 1
        );

        vm.warp(block.timestamp + 365 days);

        sablier.approve(address(memeFactory), _streamId);
        memeFactory.transferLock(_pair, address(_jose));
        address ownerOfStream = sablier.ownerOf(_streamId);
        assertTrue(ownerOfStream == address(_jose));
        vm.stopPrank();

        vm.startPrank(_jose);
        uint256 withdrawableAmount = sablier.withdrawableAmountOf(_streamId);
        memeFactory.unlockLiquidityTokens(_pair, address(_jose));
        assertTrue(
            IERC20(_pair).balanceOf(address(_jose)) == withdrawableAmount
        );

        LockupLinear.Stream memory stream = sablier.getStream(_streamId);
        assertEq(stream.isDepleted, true);
        assertTrue(stream.amounts.withdrawn == withdrawableAmount);
        withdrawableAmount = sablier.withdrawableAmountOf(_streamId);
        assertTrue(withdrawableAmount == 0);

        vm.stopPrank();
    }

    function test_WithdrawFee_Owner() public {
        uint256 tokensToLaunch = 5;

        for (uint256 i = 0; i < tokensToLaunch; i++) {
            vm.startPrank(_user);
            (, , uint256 _streamId) = _launch(
                block.timestamp + 2 days,
                i % 2 == 0 ? true : false,
                minimumLiquidityETH,
                minlockDuration + 1
            );
            if (i % 2 == 0) {
                assertTrue(_streamId == 0);
            }
            if (i % 2 != 0) {
                assertTrue(_streamId > 0);
            }
            vm.stopPrank();
        }

        vm.startPrank(_owner);
        assertEq(
            _usdc.balanceOf(address(memeFactory)),
            launchFee * tokensToLaunch
        );
        memeFactory.withdrawFee(address(_owner)); // Owner withdraws to self
        assertEq(_usdc.balanceOf(address(memeFactory)), 0);
        assertEq(_usdc.balanceOf(address(_owner)), launchFee * tokensToLaunch);

        vm.stopPrank();
    }

    function test_ChangeLaunchFee_Withdraw_Owner() public {
        vm.startPrank(_owner);
        assertEq(memeFactory.launchFee(), launchFee);
        uint256 newLaunchFee = 500 * 1e18;
        memeFactory.setLaunchFee(newLaunchFee);
        assertEq(memeFactory.launchFee(), newLaunchFee);
        vm.stopPrank();
        uint256 tokensToLaunch = 5;
        for (uint256 i = 0; i < tokensToLaunch; i++) {
            vm.startPrank(_user);
            (, , uint256 _streamId) = _launch(
                block.timestamp + 2 days,
                i % 2 == 0 ? true : false,
                minimumLiquidityETH,
                minlockDuration + 1
            );
            if (i % 2 == 0) {
                assertTrue(_streamId == 0);
            }
            if (i % 2 != 0) {
                assertTrue(_streamId > 0);
            }
            vm.stopPrank();
        }
        vm.startPrank(_owner);

        assertEq(
            _usdc.balanceOf(address(memeFactory)),
            newLaunchFee * tokensToLaunch
        );
        memeFactory.withdrawFee(address(_owner)); // Owner withdraws to self
        assertEq(_usdc.balanceOf(address(memeFactory)), 0);
        assertEq(
            _usdc.balanceOf(address(_owner)),
            newLaunchFee * tokensToLaunch
        );

        vm.stopPrank();
    }

    function test_SetVaporDexAdapter_Owner() public {
        vm.startPrank(_owner);
        assertEq(memeFactory.vaporDexAdapter(), _vaporDexAdapter);
        address newAdapter = makeAddr("newAdapter");
        memeFactory.setVaporDEXAdapter(newAdapter);
        assertEq(memeFactory.vaporDexAdapter(), newAdapter);
        vm.stopPrank();
    }

    function test_Revert_WithdrawFee_NotOwner() public {
        vm.startPrank(_user);
        _launch(
            block.timestamp + 2 days,
            true,
            minimumLiquidityETH,
            minlockDuration + 1
        );
        assertEq(_usdc.balanceOf(address(memeFactory)), launchFee);
        vm.expectRevert();
        memeFactory.withdrawFee(address(_user)); // User tries to withdraw
        vm.stopPrank();
    }

    function test_Revert_ChangeLaunchFee_NotOwner() public {
        vm.startPrank(_user);
        vm.expectRevert();
        memeFactory.setLaunchFee(500 * 1e18);
        vm.stopPrank();
    }

    function test_Revert_SetVaporDexAdapter_NotOwner() public {
        vm.startPrank(_user);
        vm.expectRevert();
        memeFactory.setVaporDEXAdapter(makeAddr("newAdapter"));
        vm.stopPrank();
    }

    function _launch(
        uint256 _releaseTime,
        bool lpBurn,
        uint256 value,
        uint40 lockDuration
    ) internal returns (address pair, address tokenAddress, uint256 streamId) {
        uint256 launchFeeContract = memeFactory.launchFee();
        _usdc.approve(address(memeFactory), launchFeeContract);

        (address _pair, address _tokenAddress, uint256 _streamId) = memeFactory
            .launch{value: value}(
            "Test Token",
            "TEST",
            1_000_000 ether,
            _releaseTime,
            lockDuration,
            lpBurn
        );

        pair = _pair;
        tokenAddress = _tokenAddress;
        streamId = _streamId;
    }
}
