// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IBTXToken {
    function mint(address to, uint256 amount, bool isReward) external;
    function convertRewardsBalance(address account) external;
}

contract BTXUnlockedAirdrop is Ownable {
    
    constructor() { }

    function airdrop(
        address[] memory users,
        uint256[] memory amounts
    ) public onlyOwner {
        IBTXToken token = IBTXToken(0xF0075b06b4229C20B7c22b7E63D90723b3551861);
        for (uint256 i = 0; i < users.length; i++) {
            token.mint(users[i], amounts[i], false);
        }
    }

    function convert(
        address[] memory users
    ) public onlyOwner {
        IBTXToken token = IBTXToken(0xF0075b06b4229C20B7c22b7E63D90723b3551861);
        for (uint256 i = 0; i < users.length; i++) {
            token.convertRewardsBalance(users[i]);
        }
    }

}
