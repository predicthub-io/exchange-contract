// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

interface IERC20Ext {
    function decimals() external view returns (uint8);

    function allowance(address owner, address spender) external view returns (uint256);
}
