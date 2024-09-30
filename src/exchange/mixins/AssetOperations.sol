// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import { IERC20 } from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import { IAssets } from "../interfaces/IAssets.sol";
import { IAssetOperations } from "../interfaces/IAssetOperations.sol";
import { IConditionalTokens } from "../interfaces/IConditionalTokens.sol";
import { TransferHelper } from "../libraries/TransferHelper.sol";
import { IERC20Ext } from "../../shares/IERC20Ext.sol";

/// @title Asset Operations
/// @notice Operations on the CTF and Collateral assets
abstract contract AssetOperations is IAssetOperations, IAssets {
    bytes32 public constant parentCollectionId = bytes32(0);

    function _getBalance(uint256 _tokenId) internal override returns (uint256) {
        if (_tokenId == 0) return IERC20(getCurrency()).balanceOf(address(this));
        return IERC20(address(uint160(_tokenId))).balanceOf(address(this));
    }

    function _transfer(address from, address to, uint256 id, uint256 value) internal override {
        if (id == 0) return _transferCollateral(from, to, value);
        return _transferConditionalToken(from, to, id, value);
    }

    function _transferCollateral(address from, address to, uint256 value) internal {
        address token = getCurrency();
        if (from == address(this)) TransferHelper._transferERC20(token, to, value);
        else TransferHelper._transferFromERC20(token, from, to, value);
    }

    function _transferConditionalToken(address from, address to, uint256 id, uint256 value) internal {
        if (from == address(this)) TransferHelper._transferERC20(address(uint160(id)), to, value);
        else TransferHelper._transferFromERC20(address(uint160(id)), from, to, value);
    }

    function _mint(bytes32 marketId, uint256 amount) internal override {
        uint256[] memory partition = new uint256[](2);
        partition[0] = 1;
        partition[1] = 2;
        IConditionalTokens(getFactory()).splitPosition(marketId, partition, amount);
    }

    function _merge(bytes32 marketId, uint256 amount) internal override {
        uint256[] memory partition = new uint256[](2);
        partition[0] = 1;
        partition[1] = 2;

        IConditionalTokens(getFactory()).mergePositions(marketId, partition, amount);
    }

    function _approveBatch(address user, bytes32 marketId, uint256 tokenId, uint256 amount) internal override {
        if (IERC20Ext(address(uint160(tokenId))).allowance(user, address(this)) < amount) {
            IConditionalTokens(factory).approveBatch(user, marketId);
        }
    }
}
