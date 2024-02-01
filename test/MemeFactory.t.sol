// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Test.sol";
import "contracts/MemeFactory.sol";
import {ISablierV2LockupLinear} from "@sablier/v2-core/src/interfaces/ISablierV2LockupLinear.sol";
import {LockupLinear} from "@sablier/v2-core/src/types/DataTypes.sol";
import {ERC20Mock} from "./mocks/ERC20Mock.sol";

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
        _usdc.mint(address(_user), launchFee);
        _usdc.approve(address(memeFactory), launchFee);
        uint _releaseTime = block.timestamp + 1 days;
        bool _lpBurn = true;

        (address _pair, address _tokenAddress) = memeFactory.launch{
            value: 10 ether
        }("Test Token", "TEST", 1_000_000 ether, _releaseTime, _lpBurn);
        assertTrue(_pair != address(0), "Pair address is zero");
        assertTrue(_tokenAddress != address(0), "Token address is zero");
        vm.stopPrank();
    }
}
