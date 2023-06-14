// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

interface IBTXToken {
    function transferFrom(address from, address to, uint256 amount) external;
    function transfer(address to, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
    function transferrableBalanceOf(address account) external view returns (uint256);
    function rewardBalanceOf(address account) external view returns (uint256);
    function isRewardConsumer(address account) external view returns (bool);
    function getUsableReward(address from, uint amount) external view returns (uint);
    function mint(address to, uint256 amount) external;
    function mint(address to, uint256 amount, bool isReward) external;
    function mintReward(address to, uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
    function burnFrom(address account, uint256 amount, bool useRewards) external;
    function burnUsingRewardsFrom(address account, uint256 amount) external;
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

contract BTXHandler is OwnableUpgradeable {
    address public btxToken;
    address public treasury;

    event BTXMinted(address indexed user, uint256 amount, string mintTag, bool isReward);
    event BTXBurned(address indexed user, uint256 amount, string burnTag);
    event BTXRewardMinted(address indexed user, uint256 amount, string mintTag);
    event BTXRewardUsed(address indexed user, uint256 amount, string useTag);
    event BTXDeposited(address indexed user, uint256 amount, string depositTag);
    event BTXSent(address indexed user, uint256 amount, string sendTag);

     /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _btxToken, address _treasury) initializer public {
        __Ownable_init();
        btxToken = _btxToken;
        treasury = _treasury;
    }

    function setBtxToken(address _gcToken) public onlyOwner {
        btxToken = _gcToken;
    }

    function setTreasury(address _treasury) public {
        require (msg.sender == treasury || msg.sender == owner(), "Not allowed");
        treasury = _treasury;
    }

    function mintBTX(
        address to,
        uint256 amount,
        string memory mintTag,
        bool isReward
    ) public onlyOwner {
        IBTXToken(btxToken).mint(to, amount, isReward);
        emit BTXMinted(to, amount, mintTag, isReward);
    }
    
    function burnBTX(
        address user,
        uint256 amount,
        uint256 permitAmount,
        string memory burnTag,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bool useRewards
    ) public onlyOwner {
        require(!IBTXToken(btxToken).getBlackListStatus(user), "User blacklisted");
        if (IBTXToken(btxToken).allowance(user, address(this)) < amount) {
            IBTXToken(btxToken).permit(
                user,
                address(this),
                permitAmount,
                type(uint256).max,
                v,
                r,
                s
            );
        }
        if (useRewards) {
            uint usableReward = IBTXToken(btxToken).getUsableReward(user, amount);
            if ( usableReward > 0) {
                emit BTXRewardUsed(user, usableReward, burnTag);
            }
        }
        IBTXToken(btxToken).burnFrom(user, amount, useRewards);
        emit BTXBurned(user, amount, burnTag);
    }

    function burnBTX(
        address user,
        uint256 amount,
        string memory burnTag,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bool useRewards
    ) public onlyOwner {
        burnBTX(user, amount, amount, burnTag, v, r, s, useRewards);
    }

    function depositFromUser(
        address user,
        uint256 amount,
        uint256 permitAmount,
        string memory depositTag,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public onlyOwner {
        require(!IBTXToken(btxToken).getBlackListStatus(user), "User blacklisted");
        if (IBTXToken(btxToken).allowance(user, address(this)) < amount) {
            IBTXToken(btxToken).permit(
                user,
                address(this),
                permitAmount,
                type(uint256).max,
                v,
                r,
                s
            );
        }
        uint usableReward = IBTXToken(btxToken).getUsableReward(user, amount);
        if ( usableReward > 0) {
            emit BTXRewardUsed(user, usableReward, depositTag);
        }
        IBTXToken(btxToken).transferFrom(user, address(this), amount);
        emit BTXDeposited(user, amount, depositTag);
    }

    function depositFromUser(
        address user,
        uint256 amount,
        string memory depositTag,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public onlyOwner {
       depositFromUser(user, amount, amount, depositTag, v, r, s);
    }

    function sendToUser(
        address user,
        uint256 amount,
        string memory sendTag
    ) public onlyOwner {
        require(!IBTXToken(btxToken).getBlackListStatus(user), "User blacklisted");
        IBTXToken(btxToken).transfer(user, amount);
        emit BTXSent(user, amount, sendTag);
    }


    function withdrawTreasury() public {
        require (msg.sender == treasury || msg.sender == owner(), "Not allowed");
        IBTXToken(btxToken).transfer(treasury, IBTXToken(btxToken).balanceOf(address(this)));
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount) public onlyOwner
    {
        IBTXToken(tokenAddress).transfer(msg.sender, tokenAmount);
    }
}
