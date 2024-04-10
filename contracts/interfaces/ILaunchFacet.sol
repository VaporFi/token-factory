// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

interface ILaunchFacet {
    //////////////
    /// EVENTS ///
    //////////////

    event TokenLaunched(
        address indexed _tokenAddress,
        address indexed _creatorAddress,
        uint256 indexed _tokenId
    );

    event StreamCreated(
        uint256 indexed _streamId,
        address indexed _sender,
        address indexed _pair
    );
    event LiquidityBurned(
        address indexed pair,
        address indexed _burner,
        uint256 _amount
    );
    event LiquidityTokensUnlocked(
        address indexed _pairAddress,
        address indexed _receiver
    );
    event LiquidityTransferred(
        address indexed _pairAddress,
        address indexed _to
    );

    function launchERC20(
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply,
        uint256 _tradingStartsAt,
        uint40 lockDuration,
        bool _burnLiquidity
    )
        external
        payable
        returns (address _pair, address _tokenAddress, uint256 streamId);
}
