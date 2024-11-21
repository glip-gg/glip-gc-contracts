// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract BTXUSDCStableSwap is AccessControl, Pausable {
    IERC20 public BTXToken;
    IERC20 public USDCToken;

    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");

    uint256 public btxToUsdcRate;

    event BTXToUSDCExchangeRateUpdated(uint256 newRate);
    event BTXSwappedForUSDC(address indexed user, uint256 btxAmount, uint256 usdcAmount);
    event USDCSwappedForBTX(address indexed user, uint256 usdcAmount, uint256 btxAmount);

    constructor(
        address _btxToken,
        address _usdcToken,
        uint256 _initialBtxToUsdcRate
    ) {
        require(_btxToken != address(0), "BTX token address cannot be zero");
        require(_usdcToken != address(0), "USDC token address cannot be zero");
        require(_initialBtxToUsdcRate > 0, "Exchange rate must be greater than zero");

        BTXToken = IERC20(_btxToken);
        USDCToken = IERC20(_usdcToken);
        btxToUsdcRate = _initialBtxToUsdcRate;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(OWNER_ROLE, msg.sender);
    }

    /**
     * @dev Allows the owner to update the BTX <-> USDC exchange rate.
     * @param _newRate New exchange rate.
     */
    function updateBTXToUSDCExchangeRate(uint256 _newRate) external onlyRole(OWNER_ROLE) {
        require(_newRate > 0, "Exchange rate must be greater than zero");
        btxToUsdcRate = _newRate;
        emit BTXToUSDCExchangeRateUpdated(_newRate);
    }

    /**
     * @dev Allows a user to swap BTX tokens for USDC at the current rate.
     * @param _btxAmount Amount of BTX tokens to swap.
     */
    function swapBTXForUSDC(uint256 _btxAmount) external whenNotPaused {
        require(_btxAmount > 0, "Amount must be greater than zero");

        // Calculate USDC amount (6 decimals)
        uint256 usdcAmount = _btxAmount / btxToUsdcRate / 10**12;
        require(
            USDCToken.balanceOf(address(this)) >= usdcAmount,
            "Insufficient USDC liquidity in contract"
        );

        // Transfer BTX tokens from user to contract
        require(
            BTXToken.transferFrom(msg.sender, address(this), _btxAmount),
            "BTX transfer failed"
        );

        // Transfer USDC tokens from contract to user
        require(
            USDCToken.transfer(msg.sender, usdcAmount),
            "USDC transfer failed"
        );

        emit BTXSwappedForUSDC(msg.sender, _btxAmount, usdcAmount);
    }


    /**
     * @dev Allows a user to swap USDC tokens for BTX at the current rate.
     * @param _usdcAmount Amount of USDC tokens to swap.
     */
    function swapUSDCForBTX(uint256 _usdcAmount) external whenNotPaused {
        require(_usdcAmount > 0, "Amount must be greater than zero");

        // Calculate BTX amount (18 decimals)
        uint256 btxAmount = (_usdcAmount * btxToUsdcRate) * 10**12;
        require(
            BTXToken.balanceOf(address(this)) >= btxAmount,
            "Insufficient BTX liquidity in contract"
        );

        // Transfer USDC tokens from user to contract
        require(
            USDCToken.transferFrom(msg.sender, address(this), _usdcAmount),
            "USDC transfer failed"
        );

        // Transfer BTX tokens from contract to user
        require(
            BTXToken.transfer(msg.sender, btxAmount),
            "BTX transfer failed"
        );

        emit USDCSwappedForBTX(msg.sender, _usdcAmount, btxAmount);
    }

    /**
     * @dev Allows the owner to withdraw USDC tokens from the contract.
     * @param _amount Amount of USDC tokens to withdraw.
     * @param _recipient Address to send the withdrawn USDC tokens.
     */
    function withdrawUSDC(uint256 _amount, address _recipient) external onlyRole(OWNER_ROLE) {
        require(_recipient != address(0), "Recipient address cannot be zero");
        require(
            USDCToken.transfer(_recipient, _amount),
            "USDC withdrawal failed"
        );
    }

    /**
     * @dev Allows the owner to withdraw BTX tokens from the contract.
     * @param _amount Amount of BTX tokens to withdraw.
     * @param _recipient Address to send the withdrawn BTX tokens.
     */
    function withdrawBTX(uint256 _amount, address _recipient) external onlyRole(OWNER_ROLE) {
        require(_recipient != address(0), "Recipient address cannot be zero");
        require(
            BTXToken.transfer(_recipient, _amount),
            "BTX withdrawal failed"
        );
    }

    /**
     * @dev Allows the owner to pause the contract, disabling swaps.
     */
    function pause() external onlyRole(OWNER_ROLE) {
        _pause();
    }

    /**
     * @dev Allows the owner to unpause the contract, enabling swaps.
     */
    function unpause() external onlyRole(OWNER_ROLE) {
        _unpause();
    }

    /**
    * @dev Returns the current state of the swap.
    * Includes BTX <-> USDC rate and the contract's token balances.
    * @return btxToUsdc Current BTX <-> USDC exchange rate.
    * @return btxBalance Contract's current BTX token balance.
    * @return usdcBalance Contract's current USDC token balance.
    */
    function getSwapState()
        external
        view
        returns (
            uint256 btxToUsdc,
            uint256 btxBalance,
            uint256 usdcBalance
        )
    {
        return (
            btxToUsdcRate,
            BTXToken.balanceOf(address(this)),
            USDCToken.balanceOf(address(this))
        );
    }

    /**
    * @dev Returns the amount of USDC that will be received for a given amount of BTX.
    * @param btxAmount Amount of BTX tokens (18 decimals).
    * @return usdcAmount Amount of USDC tokens (6 decimals) that will be received.
    */
    function getUsdcAmountForBtx(uint256 btxAmount) external view returns (uint256 usdcAmount) {
        usdcAmount = btxAmount / btxToUsdcRate / 10**12;
    }

    /**
    * @dev Returns the amount of BTX that will be received for a given amount of USDC.
    * @param usdcAmount Amount of USDC tokens (6 decimals).
    * @return btxAmount Amount of BTX tokens (18 decimals) that will be received.
    */
    function getBtxAmountForUsdc(uint256 usdcAmount) external view returns (uint256 btxAmount) {
        btxAmount = (usdcAmount * btxToUsdcRate) * 10**12;
    }
}
