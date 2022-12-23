// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IGCToken {
    function mint(address to, uint256 amount) external;
}

contract GlipGCAirdrop is Ownable {
    
    address public gcToken;

    event GCRewarded(address indexed user, uint256 amount, string rewardTag);

    constructor(address _gcToken) {
        gcToken = _gcToken;
    }

    function airdrop(
        address[] memory users,
        uint256[] memory amounts
    ) public onlyOwner {
        for (uint256 i = 0; i < users.length; i++) {
            IGCToken(gcToken).mint(users[i], amounts[i]);
            emit GCRewarded(users[i], amounts[i], 'airdrop');
        }
    }

}
