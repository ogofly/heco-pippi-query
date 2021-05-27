// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Example class - a mock class using delivering from ERC20
contract BasicTokenExample is ERC20 {
  constructor(uint256 initialBalance) ERC20("Basic", "BSC") public {
      _mint(msg.sender, initialBalance);
  }
}