// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {IAuthenticationController}from "./interfaces/IAuthenticationController.sol";

contract AuthenticationControllerTest is Test {
    IAuthenticationController auth = IAuthenticationController(0xBE10198DC8BA90a0b8427583bD745140aa4544CF);
    address deployer = 0xCf00c1ac6D26d52054ec89bE6e093F2E270D61d9;
    address _vaporDexAggregator = 0x55477d8537ede381784b448876AfAa98aa450E63;
    address _vaporDexAdapter = 0x01e5C45cB25E30860c2Fb80369A9C27628911a2b;
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;


    function setUp() public {
        vm.createSelectFork("https://api.avax.network/ext/bc/C/rpc");
    }

    function test_Setup() public {
        vm.startPrank(deployer);
        auth.getRoleAdmin(DEFAULT_ADMIN_ROLE);
        vm.stopPrank();
    }
}