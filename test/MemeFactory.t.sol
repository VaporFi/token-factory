// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.22;

// import "forge-std/Test.sol";
// import "contracts/MemeFactory.sol";

// contract MemeFactoryTest is Test {
//     MemeFactory memeFactory;
//     address _owner = makeAddr("owner");
//     address _router = 0x19C0FC4562A4b76F27f86c676eF5a7e38D12a20d;
//     address _stratosphere = 0x65eB37AeB1F2a9cE39556F80044607dD969b0336;
//     address _usdc = 0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664;
//     uint256 launchFee;

//     function setUp() public {
//         vm.createSelectFork("https://api.avax-test.network/ext/bc/C/rpc");
//         launchFee = 250 * 1 ** 6;
//         address[] memory _whitelist = new address[](2);

//         _whitelist[0] = 0x184eaB8D97cE56Cf77e2571e8f1D6F697076a831;
//         _whitelist[1] = 0x3F1aF4D92c91511A0BCe4B21bc256bF63bcab470;

//         memeFactory = new MemeFactory(
//             _owner,
//             _router,
//             _stratosphere,
//             _whitelist[0],
//             _whitelist[1],
//             _usdc,
//             launchFee,
//             _whitelist[0]
//         );
//     }

//     function test_launch() public {
//         address _user = makeAddr("user");
//         vm.deal(_user, 100 ether);
//         uint _releaseTime = block.timestamp + 1 days;

//         (address _pair, address _tokenAddress) = memeFactory.launch{
//             value: 10 ether
//         }("Test Token", "TEST", 1_000_000 ether, _releaseTime);

//         assertTrue(_pair != address(0), "Pair address is zero");
//         assertTrue(_tokenAddress != address(0), "Token address is zero");
//     }
// }
