// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {AppStorage} from "./LibAppStorage.sol";

error LibAuthorizable__OnlyAuthorized();

/// @title LibAuthorizable
library LibAuthorizable {
    /////////////
    /// LOGIC ///
    /////////////

    /// @notice Enforce only authorized address can call a certain function
    /// @param s AppStorage
    /// @param _address Address
    function enforceIsAuthorized(
        AppStorage storage s,
        address _address
    ) internal view {
        if (!s.authorized[_address]) revert LibAuthorizable__OnlyAuthorized();
    }
}
