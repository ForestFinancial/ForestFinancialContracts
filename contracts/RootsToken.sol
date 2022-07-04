// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/*
* @author Forest Financial Team
* @title Roots ERC20 token.
*/

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract RootsToken is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("Roots Token", "ROOTS") {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}