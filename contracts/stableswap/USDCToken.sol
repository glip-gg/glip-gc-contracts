// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract USDCToken is ERC20 {
    constructor() ERC20("USDC Token", "USDC") {
        _mint(msg.sender, 1_000_000 * (10**6)); // Mint 1,000,000 USDC to the deployer
    }

    function decimals() public view virtual override returns (uint8) {
        return 6; // USDC has 6 decimals
    }
}