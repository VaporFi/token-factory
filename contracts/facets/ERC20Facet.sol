// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {AppStorage} from "../libraries/LibAppStorage.sol";
import {ERC20Token} from "../tokens/ERC20Token.sol";

error ERC20Facet__WrongLaunchArguments();

contract ERC20Facet {
    AppStorage internal s;

    /**
     * @dev Creates a new Token contract with specified parameters.
     * @param name Name of the token.
     * @param symbol Symbol of the token.
     * @param totalSupply Total supply of the token.
     * @param _tradingStartsAt Timestamp when trading starts for the token.
     * @param dexAggregator Address of the decentralized exchange aggregator.
     * @param dexAdapter Address of the decentralized exchange adapter.
     * @return _token Instance of the created Token contract.
     */
    function createToken(
        string memory name,
        string memory symbol,
        uint256 totalSupply,
        uint256 _tradingStartsAt,
        address dexAggregator,
        address dexAdapter
    ) external returns (address _token) {
        if (totalSupply == 0 || _tradingStartsAt < block.timestamp + 2 days) {
            revert ERC20Facet__WrongLaunchArguments();
        }
        _token = address(
            new ERC20Token(
                name,
                symbol,
                totalSupply,
                s.Stratosphere,
                address(this),
                _tradingStartsAt,
                dexAggregator,
                dexAdapter
            )
        );
    }
}
