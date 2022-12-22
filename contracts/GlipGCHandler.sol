// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IGCToken {
    function mint(address to, uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
     function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

contract GlipGCHandler is Ownable {
    address public gcToken;

    event GCRewarded(address indexed user, uint256 amount, string rewardTag);
    event GCBurned(address indexed user, uint256 amount, string burnTag);

    constructor(address _gcToken) {
        gcToken = _gcToken;
    }

    function rewardGC(
        address to,
        uint256 amount,
        string memory rewardTag
    ) public onlyOwner {
        IGCToken(gcToken).mint(to, amount);
        emit GCRewarded(to, amount, rewardTag);
    }

    function burnGC(
        address user,
        uint256 amount,
        string memory burnTag,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public onlyOwner {
        if (IGCToken(gcToken).allowance(user, address(this)) < amount) {
            IGCToken(gcToken).permit(
                user,
                address(this),
                amount,
                type(uint256).max,
                v,
                r,
                s
            );
        }
        IGCToken(gcToken).burnFrom(user, amount);
        emit GCBurned(user, amount, burnTag);
    }
}
