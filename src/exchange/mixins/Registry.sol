// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import { IRegistry } from "../interfaces/IRegistry.sol";

struct OutcomeToken {
    uint256 complement;
    bytes32 marketId;
}

/// @title Registry
abstract contract Registry is IRegistry {
    mapping(uint256 => OutcomeToken) public registry;

    /// @notice Gets the marketId from a tokenId
    /// @param token    - The token
    function getMarketId(uint256 token) public view override returns (bytes32) {
        return registry[token].marketId;
    }

    /// @notice Gets the complement of a tokenId
    /// @param token    - The token
    function getComplement(uint256 token) public view override returns (uint256) {
        validateTokenId(token);
        return registry[token].complement;
    }

    /// @notice Validates the complement of a tokenId
    /// @param token        - The tokenId
    /// @param complement   - The complement to be validated
    function validateComplement(uint256 token, uint256 complement) public view override {
        if (getComplement(token) != complement) revert InvalidComplement();
    }

    /// @notice Validates that a tokenId is registered
    /// @param tokenId - The tokenId

    function validateTokenId(uint256 tokenId) public view override {
        if (registry[tokenId].complement == 0) revert InvalidTokenId();
    }

    function _registerToken(uint256 token0, uint256 token1, bytes32 marketId) internal {
        if (token0 == token1 || (token0 == 0 || token1 == 0)) revert InvalidTokenId();
        if (registry[token0].complement != 0 || registry[token1].complement != 0) revert AlreadyRegistered();

        registry[token0] = OutcomeToken({ complement: token1, marketId: marketId });

        registry[token1] = OutcomeToken({ complement: token0, marketId: marketId });

        emit TokenRegistered(token0, token1, marketId);
        emit TokenRegistered(token1, token0, marketId);
    }
}
