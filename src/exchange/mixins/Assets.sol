// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import { IERC20 } from "openzeppelin-contracts/token/ERC20/IERC20.sol";

import { IAssets } from "../interfaces/IAssets.sol";

abstract contract Assets is IAssets {
    address internal immutable currency;
    address internal immutable predictHubFactory;

    constructor(address _currency, address _predictHubFactory) {
        currency = _currency;
        predictHubFactory = _predictHubFactory;
        IERC20(currency).approve(predictHubFactory, type(uint256).max);
    }

    function getCurrency() public view override returns (address) {
        return currency;
    }

    function getFactory() public view override returns (address) {
        return predictHubFactory;
    }
}
