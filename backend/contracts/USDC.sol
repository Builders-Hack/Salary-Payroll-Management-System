// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract USDC is ERC20("PayRight", "PRT"){
    address owner;
    constructor() {
        owner = msg.sender;
        _mint(address(this), 500000e18);
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "no permission!");
        _;
    }

    function transferFromContract(address _to, uint256 amount) external onlyOwner {
        uint bal = balanceOf(address(this));
        require(bal >= amount, "You are transferring more than the amount available!");
        _transfer(address(this), _to, amount);
    }
}