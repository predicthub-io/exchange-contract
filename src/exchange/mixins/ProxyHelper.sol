// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;
import "openzeppelin-contracts/access/Ownable.sol";
import { PredictHubProxyLib } from "../libraries/PredictHubProxyLib.sol";
import { PredictHubSafeLib } from "../libraries/PredictHubSafeLib.sol";

interface IPredictHubSafeFactory {
    function masterCopy() external view returns (address);
}

interface IPredictHubProxyWalletFactory {
    function checkProxyWalletAddress(address, address) external view returns (bool);

    function computeProxyAddress(address user, bytes32 salt) external view returns (address);
}

contract ProxyHelper is Ownable {
    /// @notice The PredictHub Proxy Wallet Factory Contract
    address public proxyFactory;
    /// @notice The PredictHub Gnosis Safe Factory Contract
    address public safeFactory;

    event ProxyFactoryUpdated(address indexed oldProxyFactory, address indexed newProxyFactory);

    event SafeFactoryUpdated(address indexed oldSafeFactory, address indexed newSafeFactory);

    constructor(address _proxyFactory, address _safeFactory) {
        proxyFactory = _proxyFactory;
        safeFactory = _safeFactory;
    }

    /// @notice Gets the Safe factory implementation address
    function getSafeFactoryImplementation() public view returns (address) {
        return IPredictHubSafeFactory(safeFactory).masterCopy();
    }

    /// @notice Gets the PredictHub proxy wallet address for an address
    /// @param _signer    - The address that managers the proxy wallet
    /// @param _proxy    - The proxy address to verify
    function checkProxyWalletAddress(address _signer, address _proxy) public view returns (bool) {
        return IPredictHubProxyWalletFactory(proxyFactory).checkProxyWalletAddress(_signer,_proxy);
    }

    /// @notice Gets the PredictHub Gnosis Safe address for an address
    /// @param _addr    - The address that owns the proxy wallet
    function getProxyAddress(address _addr, bytes32 _salt) public view returns (address) {
        return IPredictHubProxyWalletFactory(proxyFactory).computeProxyAddress(_addr, _salt);
    }

    /// @notice Gets the PredictHub Gnosis Safe address for an address
    /// @param _addr    - The address that owns the proxy wallet
    function getSafeAddress(address _addr) public view returns (address) {
        return PredictHubSafeLib.getSafeAddress(_addr, getSafeFactoryImplementation(), safeFactory);
    }

    function setProxyFactory(address _proxyFactory) external onlyOwner {
        emit ProxyFactoryUpdated(proxyFactory, _proxyFactory);
        proxyFactory = _proxyFactory;
    }

    function setSafeFactory(address _safeFactory) external onlyOwner {
        emit SafeFactoryUpdated(safeFactory, _safeFactory);
        safeFactory = _safeFactory;
    }
}
