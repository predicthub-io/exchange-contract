// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

abstract contract IAssetOperations {
    function _getBalance(uint256 tokenId) internal virtual returns (uint256);

    function _transfer(address from, address to, uint256 id, uint256 value) internal virtual;

    function _mint(bytes32 marketId, uint256 amount) internal virtual;

    function _merge(bytes32 marketId, uint256 amount) internal virtual;

    function _approveBatch(address user, bytes32 marketId, uint256 tokenId, uint256 amount) internal virtual;
}
