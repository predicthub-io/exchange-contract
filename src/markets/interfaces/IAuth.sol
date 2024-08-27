// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IAuth {
    function isAdmin(address) external view returns (bool);

    function isApprover(address) external view returns (bool);
}
