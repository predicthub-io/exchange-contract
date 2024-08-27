// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IUmaAdapter {
    function isWhitelistCurrency(address _currency) external view returns (bool);
}
