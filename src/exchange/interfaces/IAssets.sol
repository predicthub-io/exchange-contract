// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

abstract contract IAssets {
    function getCurrency() public virtual returns (address);

    function getFactory() public virtual returns (address);
}
