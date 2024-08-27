// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import { PredictHubSafeLib } from "../libraries/PredictHubSafeLib.sol";
import { PredictHubProxyLib } from "../libraries/PredictHubProxyLib.sol";

interface IPredictProxyFactory {
    function getImplementation() external view returns (address);
}

interface IPredictHubSafeFactory {
    function masterCopy() external view returns (address);
}

interface IProxyHelper {
    function checkProxyWalletAddress(address _proxy, address _deployer) external view returns (bool);

    function getSafeAddress(address _addr) external view returns (address);
}

abstract contract PredictHubFactoryHelper {
    address public proxyHelper;

    event ProxyHelperUpdated(address indexed oldAddress, address indexed newAddress);

    constructor(address _proxyHelper) {
        proxyHelper = _proxyHelper;
    }

    /// @notice Gets the BaseCaster proxy wallet address for an address
    /// @param _signer    - The address that managers the proxy wallet
    /// @param _proxy    - The proxy address to verify
    function checkProxyWalletAddress(address _signer, address _proxy) public view returns (bool) {
        return IProxyHelper(proxyHelper).checkProxyWalletAddress(_proxy, _signer);
    }

    /// @notice Gets the BaseCaster Gnosis Safe address for an address
    /// @param _addr    - The address that owns the proxy wallet
    function getSafeAddress(address _addr) public view returns (address) {
        return IProxyHelper(proxyHelper).getSafeAddress(_addr);
    }

    function _setProxyHelper(address _proxyHelper) internal {
        emit ProxyHelperUpdated(proxyHelper, _proxyHelper);
        proxyHelper = _proxyHelper;
    }
}
