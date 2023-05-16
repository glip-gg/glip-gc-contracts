// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "./contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "./contracts-upgradeable/security/PausableUpgradeable.sol";
import "./contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "./contracts-upgradeable/proxy/utils/Initializable.sol";

contract BtxToken is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, PausableUpgradeable, AccessControlUpgradeable, ERC20PermitUpgradeable {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant REWARD_ROLE = keccak256("REWARD_ROLE");

    event DestroyedBlackFunds(address _blackListedUser, uint _balance);
    event AddedBlackList(address _user);
    event RemovedBlackList(address _user);


    mapping(address => uint256) private _rewardBalances;
    mapping (address => bool) private _whitelistedRewardConsumers;
    mapping (address => bool) public isBlackListed;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __ERC20_init("BTXToken", "BTX");
        __ERC20Burnable_init();
        __Pausable_init();
        __AccessControl_init();
        __ERC20Permit_init("BTXToken");

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(REWARD_ROLE, msg.sender);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function mintReward(address to, uint256 amount) public onlyRole(REWARD_ROLE) {
        require(to != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), to, amount);
        _totalSupply += amount;
        unchecked {
            _rewardBalances[to] += amount;
        }
        emit Transfer(address(0), to, amount);
        _afterTokenTransfer(address(0), to, amount);
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return transferrableBalanceOf(account) + rewardBalanceOf(account);
    }

    function transferrableBalanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function rewardBalanceOf(address account) public view returns (uint256) {
        return _rewardBalances[account];
    }

    function whitelistRewardConsumer(address _address) public onlyRole(MINTER_ROLE) {
        _whitelistedRewardConsumers[_address] = true;
    }

    function removeWhitelistRewardConsumer(address _address) public onlyRole(MINTER_ROLE) {
        _whitelistedRewardConsumers[_address] = false;
    }

    function isRewardConsumer(address _address) public view returns (bool) {
        return _whitelistedRewardConsumers[_address];
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

        _adjustBalances(from, to, amount);
    
        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _adjustBalances(
        address from,
        address to,
        uint256 amount
    ) internal {
        // if target address is not reward whitelisted, then use balance only
        // reward balance can only be transferred to reward whitelisted addresses (or null address)
        // when reward balance is transferred to whitelisted address, it gets converted to the actual balance of receiever 
        if (_whitelistedRewardConsumers[to]) {
             // 3 cases - 
            // reward balance > 0 and > amount -> use reward
            // reward balance > 0 and < amount -> use reward and transfer from balance
            // reward balance = 0 -> use balance
            uint256 fromRewardBalance = _rewardBalances[from];
            if (fromRewardBalance > 0 && fromRewardBalance >= amount) {
                // use reward balance only
                unchecked {
                    _rewardBalances[from] = fromRewardBalance - amount;
                    // gets converted to the actual balance of receiever 
                    if (to != address(0)) {
                        _balances[to] += amount;
                    }
                }
            } else if (fromRewardBalance > 0 && fromRewardBalance < amount) {
                // use complete reward balance and actual balance for remainder
                unchecked {
                    _rewardBalances[from] = 0;

                    uint256 remainder = amount - fromRewardBalance;

                    uint256 fromBalance = _balances[from];
                    require(fromBalance >= remainder, "ERC20: transfer amount exceeds balance. Not enough reward balance");
                    _balances[from] = fromBalance - remainder;
                    if (to != address(0)) {
                        _balances[to] += amount;
                    }
                }
            } else {
                // use balance only
                uint256 fromBalance = _balances[from];
                require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
                 _balances[from] = fromBalance - amount;
                if (to != address(0)) {
                    _balances[to] += amount;
                }
            }
        } else {
            // use balance only
             uint256 fromBalance = _balances[from];
             require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
             unchecked {
                _balances[from] = fromBalance - amount;
                if (to != address(0)) {
                    _balances[to] += amount;
                }
            }
        }
    }

     function _burn(address account, uint256 amount) internal virtual override {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = balanceOf(account);
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");

        _totalSupply -= amount;

        _adjustBalances(account, address(0), amount);

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
        unchecked {
            _rewardBalances[_blackListedUser] = 0;
            _totalSupply -= dirtyFunds;
        }
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
}