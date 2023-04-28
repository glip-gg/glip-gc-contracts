// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IGCToken {
    function transferFrom(address from, address to, uint256 amount) external;
    function transfer(address to, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
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
    function getBlackListStatus(address _user) external view returns (bool);
}

contract BtxGCHandler is Ownable {
    address public gcToken;
    address public treasury;

    event GCDeposited(address indexed user, uint256 amount, string depositTag);
    event GCSent(address indexed user, uint256 amount, string sendTag);

    constructor(address _gcToken, address _treasury) {
        gcToken = _gcToken;
        treasury = _treasury;
    }

    function setGcToken(address _gcToken) public onlyOwner {
        gcToken = _gcToken;
    }

    function setTreasury(address _treasury) public {
        require (msg.sender == treasury || msg.sender == owner(), "Not allowed");
        treasury = _treasury;
    }

    function depositFromUser(
        address user,
        uint256 amount,
        string memory depositTag,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public onlyOwner {
        require(!IGCToken(gcToken).getBlackListStatus(user), "User blacklisted");
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
        IGCToken(gcToken).transferFrom(user, address(this), amount);
        emit GCDeposited(user, amount, depositTag);
    }

    function sendToUser(
        address user,
        uint256 amount,
        string memory sendTag
    ) public onlyOwner {
        require(!IGCToken(gcToken).getBlackListStatus(user), "User blacklisted");
        IGCToken(gcToken).transfer(user, amount);
        emit GCSent(user, amount, sendTag);
    }

    function withdrawTreasury() public {
        require (msg.sender == treasury || msg.sender == owner(), "Not allowed");
        IGCToken(gcToken).transfer(treasury, IGCToken(gcToken).balanceOf(address(this)));
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount) public onlyOwner
    {
        IGCToken(tokenAddress).transfer(msg.sender, tokenAmount);
    }
}
