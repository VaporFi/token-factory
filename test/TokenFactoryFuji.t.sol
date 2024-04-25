// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { ISablierV2LockupLinear } from "@sablier/v2-core/src/interfaces/ISablierV2LockupLinear.sol";
import { LockupLinear } from "@sablier/v2-core/src/types/DataTypes.sol";
import { ERC20Mock } from "./mocks/ERC20Mock.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { LockupLinear } from "@sablier/v2-core/src/types/DataTypes.sol";
import { IUniswapV3PoolState } from "./interfaces/IUniswapV3PoolState.sol";
import { TokenFactoryDiamondBaseTest } from "./TokenFactoryDiamondBase.t.sol";
import { TokenFactoryDiamond } from "contracts/TokenFactoryDiamond.sol";
import { DiamondInit } from "contracts/upgradeInitializers/DiamondInit.sol";
import { AdminFacet } from "contracts/facets/AdminFacet.sol";
import { LaunchERC20Facet } from "contracts/facets/LaunchERC20Facet.sol";
import { LiquidityLockFacet } from "contracts/facets/LiquidityLockFacet.sol";

contract TokenFactoryFujiTest is TokenFactoryDiamondBaseTest {
  TokenFactoryDiamond tokenFactory;
  AdminFacet internal adminFacet;
  LaunchERC20Facet internal launchFacet;
  LiquidityLockFacet internal liquidityLockFacet;

  address _teamMultiSig = makeAddr("teamMultiSig");
  address _router = 0x19C0FC4562A4b76F27f86c676eF5a7e38D12a20d;
  address _factory = 0xC009a670E2B02e21E7e75AE98e254F467f7ae257;
  address _stratosphere = 0x65eB37AeB1F2a9cE39556F80044607dD969b0336;
  address _vaporDexAggregator = 0x55477d8537ede381784b448876AfAa98aa450E63;
  address _vaporDexAdapter = 0x3F1aF4D92c91511A0BCe4B21bc256bF63bcab470;
  address _vape = 0x3bD01B76BB969ef2D5103b5Ea84909AD8d345663;
  address _weth = 0xd00ae08403B9bbb9124bB305C09058E32C39A48c;
  address _liquidityPositionManager = 0x7a0A7C4273B25b3a71Daeaa387c7855081AC4E56;
  IERC20 _usdc = IERC20(0xeA42E3030ab1406a0b6aAd077Caa927673a2c302); // real USDC
  IUniswapV3PoolState _vapeUsdcPool = IUniswapV3PoolState(0xb1ca210D7429584eF3B50cD32B564b4f72b9D07c); // VAPE/USDC Pool
  ISablierV2LockupLinear sablier = ISablierV2LockupLinear(0xebf7ed508a0Bb1c4e66b9E6F8C6a73342E7049ac);
  // Addresses that hold USDC on testnet
  address _user = 0xbbE2B49D637629280543d9550bceB80bF802287e;
  address _jose = 0xbbE2B49D637629280543d9550bceB80bF802287e;
  address _hitesh = 0xbbE2B49D637629280543d9550bceB80bF802287e;
  address _roy = 0xbbE2B49D637629280543d9550bceB80bF802287e;
  address _renegade = 0x9A9f01c11E03042E7763e9305f36FF18f0add81B;

  uint256 launchFee = 250 * 1e6;
  // Minimum liquidity required to create a pair on VaporDEXV1 Pool
  uint256 minimumLiquidity = 10 ** 3; // https://github.com/VaporFi/vapordex-contracts/blob/staging/contracts/VaporDEX/VaporDEXPair.sol#L21
  uint256 minimumLiquidityETH = 10 ether; // to create token
  uint40 minlockDuration = 90; // 3 months
  uint256 slippage = 10000; // 100%

  function setUp() public {
    vm.createSelectFork("https://rpc.ankr.com/avalanche_fuji");

    vm.deal(_user, 10000000 ether);
    vm.deal(_jose, 10000000 ether);
    vm.deal(_hitesh, 10000000 ether);
    vm.deal(_roy, 10000000 ether);

    vm.startPrank(_diamondOwner);

    DiamondInit.DeployArgs memory _initArgs;
    _initArgs.routerAddress = _router;
    _initArgs.factoryAddress = _factory;
    _initArgs.stratosphereAddress = _stratosphere;
    _initArgs.vaporDexAggregator = _vaporDexAggregator;
    _initArgs.vaporDexAdapter = _vaporDexAdapter;
    _initArgs.vape = _vape;
    _initArgs.usdc = address(_usdc);
    _initArgs.weth = _weth;
    _initArgs.launchFee = launchFee;
    _initArgs.minLiquidityETH = minimumLiquidityETH;
    _initArgs.minLockDuration = minlockDuration;
    _initArgs.sablier = address(sablier);
    _initArgs.nonFungiblePositionManager = _liquidityPositionManager;
    _initArgs.teamMultisig = _teamMultiSig;
    _initArgs.slippage = slippage;

    tokenFactory = createDiamond(_initArgs);
    adminFacet = AdminFacet(address(tokenFactory));
    launchFacet = LaunchERC20Facet(address(tokenFactory));
    liquidityLockFacet = LiquidityLockFacet(address(tokenFactory));

    vm.stopPrank();

    // A dummy launch to increase liquidity in the pool for full range
    vm.startPrank(_user);
    _launch(block.timestamp + 2 days, false, minimumLiquidityETH, minlockDuration);
    vm.stopPrank();
  }

  function test_MinimumLiquidityETH() public {
    vm.startPrank(_user);

    _launch(block.timestamp + 2 days, true, 11 ether, minlockDuration + 1);

    vm.stopPrank();
  }

  function test_Revert_MinimumLiquidityETH() public {
    vm.startPrank(_user);
    uint256 launchFeeContract = adminFacet.getLaunchFee();
    _usdc.approve(address(tokenFactory), launchFeeContract);

    vm.expectRevert();

    launchFacet.launchERC20{ value: minimumLiquidityETH - 1 }(
      "Test Token",
      "TEST",
      1_000_000 ether,
      block.timestamp + 2 days,
      minlockDuration,
      true,
      true
    );

    vm.stopPrank();
  }

  function test_Revert_SetMinimumLiquidityETH() public {
    vm.startPrank(_user);
    vm.expectRevert();
    adminFacet.setMinimumLiquidityETH(3 ether);
    vm.stopPrank();
  }

  function test_Revert_SetMinimumLockDuration() public {
    vm.startPrank(_user);
    vm.expectRevert();
    adminFacet.setMinLockDuration(30);
    vm.stopPrank();
  }

  function test_LaunchWithLPBurn() public {
    vm.startPrank(_user);
    uint256 vapeUsdcPoolLiquidityBeforeLaunch = _vapeUsdcPool.liquidity();
    (address _pair, address _tokenAddress, uint256 _streamId) = _launch(
      block.timestamp + 2 days,
      true,
      minimumLiquidityETH,
      minlockDuration + 1
    );

    uint256 vapeUsdcPoolLiquidityAfterLaunch = _vapeUsdcPool.liquidity();
    // Pair and Token Checks
    assertTrue(_pair != address(0), "Pair address is zero");
    assertTrue(_tokenAddress != address(0), "Token address is zero");
    assertTrue(IERC20(_pair).balanceOf(address(0)) > minimumLiquidity, "Pair balance is zero");
    assertTrue(vapeUsdcPoolLiquidityAfterLaunch > vapeUsdcPoolLiquidityBeforeLaunch, "Liquidity not added to pool");

    // Stream Checks
    assertTrue(_streamId == 0);

    vm.stopPrank();
  }

  // no sablier in fuji, commented them
  function test_Revert_LaunchWithLPLock() public {
    vm.startPrank(_user);

    uint256 launchFeeContract = adminFacet.getLaunchFee();
    _usdc.approve(address(tokenFactory), launchFeeContract);

    vm.expectRevert();

    launchFacet.launchERC20{ value: minimumLiquidityETH }(
      "Test Token",
      "TEST",
      1_000_000 ether,
      block.timestamp + 2 days,
      minlockDuration - 1,
      false,
      true
    );

    vm.stopPrank();
  }

  function test_LaunchWithLPLock() public {
    vm.startPrank(_user);
    uint40 lockDuration = minlockDuration + 1;
    (address _pair, address _tokenAddress, uint256 _streamId) = _launch(
      block.timestamp + 2 days,
      false,
      minimumLiquidityETH,
      lockDuration
    );

    // Pair and Token Checks
    assertTrue(_pair != address(0), "Pair address is zero");
    assertTrue(_tokenAddress != address(0), "Token address is zero");
    assertTrue(IERC20(_pair).balanceOf(address(0)) == minimumLiquidity);

    // Stream Checks
    assertTrue(_streamId > 0);

    LockupLinear.Stream memory stream = sablier.getStream(_streamId);
    assertEq(stream.endTime, block.timestamp + lockDuration * 1 days);
    assertEq(stream.isTransferable, true);
    assertEq(stream.isCancelable, false);

    address ownerOfStream = sablier.ownerOf(_streamId);
    assertTrue(ownerOfStream == _user);

    vm.stopPrank();
  }

  function test_LPUnlock() public {
    vm.startPrank(_user);
    uint40 lockDuration = minlockDuration + 1;
    (address _pair, address _tokenAddress, uint256 _streamId) = _launch(
      block.timestamp + 2 days,
      false,
      minimumLiquidityETH,
      lockDuration
    );

    // Before Warp
    LockupLinear.Stream memory stream = sablier.getStream(_streamId);
    assertTrue(IERC20(_pair).balanceOf(address(_user)) == 0);
    assertEq(stream.isDepleted, false);
    assertTrue(stream.amounts.withdrawn == 0);
    assertTrue(sablier.withdrawableAmountOf(_streamId) == 0);

    vm.warp(block.timestamp + lockDuration * 1 days);

    // After Warp
    uint256 withdrawableAmount = sablier.withdrawableAmountOf(_streamId);
    assertTrue(withdrawableAmount > 0);

    liquidityLockFacet.unlockLiquidityTokens(_tokenAddress, address(_user));
    assertTrue(IERC20(_pair).balanceOf(address(_user)) == withdrawableAmount);

    stream = sablier.getStream(_streamId);

    assertEq(stream.isDepleted, true);
    assertTrue(stream.amounts.withdrawn == withdrawableAmount);
    withdrawableAmount = sablier.withdrawableAmountOf(_streamId);
    assertTrue(withdrawableAmount == 0);

    vm.stopPrank();
  }

  function test_LPTransfer_BeforeUnlock() public {
    vm.startPrank(_user);
    (address _pair, address _tokenAddress, uint256 _streamId) = _launch(
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

    sablier.approve(address(tokenFactory), _streamId);
    liquidityLockFacet.transferLock(_tokenAddress, address(_jose));
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
    uint40 lockDuration = minlockDuration + 1;
    (address _pair, address _tokenAddress, uint256 _streamId) = _launch(
      block.timestamp + 2 days,
      false,
      minimumLiquidityETH,
      minlockDuration + 1
    );

    vm.warp(block.timestamp + lockDuration * 1 days);

    sablier.approve(address(tokenFactory), _streamId);
    liquidityLockFacet.transferLock(_tokenAddress, _renegade);
    address ownerOfStream = sablier.ownerOf(_streamId);
    assertTrue(ownerOfStream == _renegade);
    vm.stopPrank();

    vm.startPrank(_renegade);
    uint256 withdrawableAmount = sablier.withdrawableAmountOf(_streamId);
    liquidityLockFacet.unlockLiquidityTokens(_tokenAddress, _renegade);
    assertTrue(IERC20(_pair).balanceOf(_renegade) == withdrawableAmount);

    LockupLinear.Stream memory stream = sablier.getStream(_streamId);
    assertEq(stream.isDepleted, true);
    assertTrue(stream.amounts.withdrawn == withdrawableAmount);
    withdrawableAmount = sablier.withdrawableAmountOf(_streamId);
    assertTrue(withdrawableAmount == 0);

    vm.stopPrank();
  }

  function test_ChangeLaunchFee_Withdraw_Owner() public {
    vm.startPrank(_diamondOwner);
    assertEq(adminFacet.getLaunchFee(), launchFee);
    uint256 newLaunchFee = 500 * 1e6;
    adminFacet.setLaunchFee(newLaunchFee);
    assertEq(adminFacet.getLaunchFee(), newLaunchFee);
    vm.stopPrank();
  }

  function test_SetVaporDexAdapter_Owner() public {
    vm.startPrank(_diamondOwner);
    assertEq(adminFacet.getVaporDEXAdapter(), _vaporDexAdapter);
    address newAdapter = makeAddr("newAdapter");
    adminFacet.setVaporDEXAdapter(newAdapter);
    assertEq(adminFacet.getVaporDEXAdapter(), newAdapter);
    vm.stopPrank();
  }

  function test_Revert_ChangeLaunchFee_NotOwner() public {
    vm.startPrank(_user);
    vm.expectRevert();
    adminFacet.setLaunchFee(500 * 1e6);
    vm.stopPrank();
  }

  function test_Revert_SetVaporDexAdapter_NotOwner() public {
    vm.startPrank(_user);
    vm.expectRevert();
    adminFacet.setVaporDEXAdapter(makeAddr("newAdapter"));
    vm.stopPrank();
  }

  function _launch(
    uint256 _releaseTime,
    bool lpBurn,
    uint256 value,
    uint40 lockDuration
  ) internal returns (address pair, address tokenAddress, uint256 streamId) {
    uint256 launchFeeContract = adminFacet.getLaunchFee();
    _usdc.approve(address(tokenFactory), launchFeeContract);

    (address _pair, address _tokenAddress, uint256 _streamId) = launchFacet.launchERC20{ value: value }(
      "Test Token",
      "TEST",
      1_000_000 ether,
      _releaseTime,
      lockDuration,
      lpBurn,
      true
    );

    pair = _pair;
    tokenAddress = _tokenAddress;
    streamId = _streamId;
  }
}
