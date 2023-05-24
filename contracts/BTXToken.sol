// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./contracts//token/ERC20/ERC20.sol";
import "./contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "./contracts/security/Pausable.sol";
import "./contracts/access/AccessControl.sol";
import "./contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract BTXToken is ERC20, ERC20Burnable, Pausable, AccessControl, ERC20Permit {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    event DestroyedBlackFunds(address _blackListedUser, uint _balance);
    event AddedBlackList(address _user);
    event RemovedBlackList(address _user);
    event RewardsConverted(address _user, uint _balance);
    event RewardsConsumed(address _user, uint _amount);
    event RewardsMinted(address _user, uint _amount);

    mapping(address => uint256) private _rewardBalances;
    mapping (address => bool) private _whitelistedRewardConsumers;
    mapping (address => bool) public isBlackListed;

    constructor() ERC20("BTXToken", "BTX") ERC20Permit("BTXToken") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }


    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _internalMint(to, amount, false);
    }

    function mint(address to, uint256 amount, bool isReward) public onlyRole(MINTER_ROLE) {
       _internalMint(to, amount, isReward);
    }

    function _internalMint(address to, uint256 amount, bool isReward) internal {
        if (!isReward) {
            _mint(to, amount);
        } else {
            require(to != address(0), "ERC20: mint to the zero address");
            _beforeTokenTransfer(address(0), to, amount);
            _totalSupply += amount;
            _rewardBalances[to] += amount;
            emit Transfer(address(0), to, amount);
            _afterTokenTransfer(address(0), to, amount);
            emit RewardsMinted(to, amount);
        }
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account] + _rewardBalances[account];
    }

    function transferrableBalanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function rewardBalanceOf(address account) public view returns (uint256) {
        return _rewardBalances[account];
    }

    function addRewardConsumer(address _address) public onlyRole(MINTER_ROLE) {
        _whitelistedRewardConsumers[_address] = true;
    }

    function removeRewardConsumer(address _address) public onlyRole(MINTER_ROLE) {
        _whitelistedRewardConsumers[_address] = false;
    }

    function isRewardConsumer(address _address) public view returns (bool) {
        return _whitelistedRewardConsumers[_address];
    }


    function convertRewardsBalance(address account) public onlyRole(MINTER_ROLE) {
        uint256 rewardBalance = _rewardBalances[account];
        require(rewardBalance > 0, "ERC20: no reward balance to convert");
        _rewardBalances[account] = 0;
        _balances[account] += rewardBalance;
        emit RewardsConverted(account, rewardBalance);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        if (to != address(0)) {
            require(!isBlackListed[from]);
        }
       
        super._beforeTokenTransfer(from, to, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = balanceOf(from);
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");

        _adjustBalances(from, to, amount, _whitelistedRewardConsumers[to]);
    
        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _adjustBalances(
        address from,
        address to,
        uint256 amount,
        bool useReward
    ) internal {
        if (useReward) {
             // 3 cases - 
            // reward balance > 0 and > amount -> use reward
            // reward balance > 0 and < amount -> use reward and transfer from balance
            // reward balance = 0 -> use balance
            uint256 fromRewardBalance = _rewardBalances[from];
            if (fromRewardBalance > 0 && fromRewardBalance >= amount) {
                 _rewardBalances[from] -= amount;
                // rewards gets converted to actual balance of receiever
                if (to != address(0)) {
                    _balances[to] += amount;
                }
                emit RewardsConsumed(from, amount);
            } else if (fromRewardBalance > 0 && fromRewardBalance < amount) {
                _rewardBalances[from] -= fromRewardBalance;

                uint remainder = amount - fromRewardBalance;
                require(_balances[from] >= remainder, "ERC20: transferrable amount exceeds balance");
                _balances[from] -= remainder;
                if (to != address(0)) {
                    _balances[to] += amount;
                }

                emit RewardsConsumed(from, fromRewardBalance);
            } else {
                require(_balances[from] >= amount, "ERC20: transferrable amount exceeds balance");
                _balances[from] -= amount;
                if (to != address(0)) {
                    _balances[to] += amount;
                }
            }
        } else {
            require(_balances[from] >= amount, "ERC20: transferrable amount exceeds balance");
            _balances[from] -= amount;
            if (to != address(0)) {
                _balances[to] += amount;
            }
        }
       
    }

    function _burn(address account, uint256 amount) internal virtual override {
        _internalBurn(account, amount, false);
    }

    function burn(uint256 amount, bool useRewards) public {
        _internalBurn(_msgSender(), amount, useRewards);
    }

    function burnFrom(address account, uint256 amount, bool useRewards) public {
        _spendAllowance(account, _msgSender(), amount);
        _internalBurn(account, amount, useRewards);
    }

    function _internalBurn(address account, uint256 amount, bool useRewards) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = balanceOf(account);
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");

        _totalSupply -= amount;

        _adjustBalances(account, address(0), amount, useRewards);

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function getBlackListStatus(address _user) external view returns (bool) {
        return isBlackListed[_user];
    }

    function addBlackList (address _evilUser) public onlyRole(PAUSER_ROLE) {
        isBlackListed[_evilUser] = true;
        emit AddedBlackList(_evilUser);
    }

    function removeBlackList (address _clearedUser) public onlyRole(PAUSER_ROLE) {
        isBlackListed[_clearedUser] = false;
        emit RemovedBlackList(_clearedUser);
    }

    function destroyRewards(address _blackListedUser) public onlyRole(PAUSER_ROLE) {
        require(isBlackListed[_blackListedUser]);
        uint256 dirtyFunds = _rewardBalances[_blackListedUser];
        _rewardBalances[_blackListedUser] = 0;
         _totalSupply -= dirtyFunds;
        emit Transfer(_blackListedUser, address(0), dirtyFunds);
        emit DestroyedBlackFunds(_blackListedUser, dirtyFunds);
    }

    function destroyBlackFunds (address _blackListedUser) public onlyRole(PAUSER_ROLE) {
        require(isBlackListed[_blackListedUser]);
        destroyRewards(_blackListedUser);
        uint dirtyFunds = balanceOf(_blackListedUser);
        _burn(_blackListedUser, dirtyFunds);
        emit DestroyedBlackFunds(_blackListedUser, dirtyFunds);
    }

    function getUsableReward(address user, uint amount) public view returns (uint) {
        uint256 fromRewardBalance = _rewardBalances[user];
        if (fromRewardBalance > 0 && fromRewardBalance >= amount) {
            return amount;
        } else if (fromRewardBalance > 0 && fromRewardBalance < amount) {
            return fromRewardBalance;
        } else {
            return 0;
        }
    }
}