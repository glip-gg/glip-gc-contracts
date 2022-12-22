// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IPermitToken {
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);

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

contract GlipGaslessFund is Ownable {

    address public feesToken;

    event GasFunded(
        address indexed user,
        uint256 fundAmount,
        uint256 feesAmount
    );

    event GaslessTransfer(
        address indexed user,
        address token,
        uint256 amount,
        uint256 feesAmount
    );

    constructor(address _feesToken) {
        feesToken = _feesToken;
    }

    function setFeesToken(address _feesToken) public onlyOwner {
        feesToken = _feesToken;
    }

    function fundGasWithFeesPermit(
        address user,
        uint256 feesAmount,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable onlyOwner {
        _transferWithPermit(feesToken, user, address(this), feesAmount, v, r, s);
        payable(user).transfer(msg.value);
        emit GasFunded(user, msg.value, feesAmount);
    }

    function gaslessTransferWithFeesPermit(
        address user,
        address transferToken,
        uint256 transferAmount,
        address transferTo,
        uint256 feesAmount,
        uint8 feesPermitV,
        bytes32 feesPermitR,
        bytes32 feesPermitS,
        uint8 transferPermitV,
        bytes32 transferPermitR,
        bytes32 transferPermitS
    ) public payable onlyOwner {
        _transferWithPermit(feesToken, user, address(this), feesAmount, feesPermitV, feesPermitR , feesPermitS);
        _transferWithPermit(transferToken, user, transferTo, transferAmount, transferPermitV, transferPermitR, transferPermitS);
        emit GaslessTransfer(user, transferToken, transferAmount, feesAmount);
    }


    function _transferWithPermit(
        address token,
        address from,
        address to,
        uint256 amount,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        if (IPermitToken(token).allowance(from, address(this)) < amount) {
            IPermitToken(token).permit(
                from,
                address(this),
                amount,
                type(uint256).max,
                v,
                r,
                s
            );
        }
        require(
            IPermitToken(token).transferFrom(from, to, amount)
        );
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount)
        public
        onlyOwner
    {
        IPermitToken(tokenAddress).transfer(msg.sender, tokenAmount);
    }
}
