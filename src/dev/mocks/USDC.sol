// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { ERC20 } from "openzeppelin-contracts/token/ERC20/ERC20.sol";

contract USDC is ERC20 {
    constructor() ERC20("MockUsdc", "MockUsdc") {}

    function mint(address _to, uint256 _amount) external {
        _mint(_to, _amount);
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }
}
