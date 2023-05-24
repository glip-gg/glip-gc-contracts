// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IBTXToken {
    function mint(address to, uint256 amount, bool isReward) external;
}

contract BTXAirdrop is Ownable {
    
    constructor() { }

    function airdrop(
        address[] memory users,
        uint256[] memory amounts
    ) public onlyOwner {
        IBTXToken token = IBTXToken(0x3C56947856B99B06aa076ada73341Efc0843d540);
        for (uint256 i = 0; i < users.length; i++) {
            token.mint(users[i], amounts[i], true);
        }
    }

}
