// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/******************************************************************************\
*
* @author Forest Financial Team
* @title ERC20 Token contract with SellTax
*
/******************************************************************************/

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./implementations/SellTax.sol";

contract ForestToken is ERC20, ERC20Burnable, Ownable, SellTax {
    using SafeMath for uint256;

    event TransferFromWithTax(uint256 _taxAmount);
    event TransferWithTax(uint256 _taxAmount);

    bool public disableTaxRequirement = false; // If set to true, tax implementation will never be used. 

    constructor(address _taxReceiver, uint256 _totalSupply) ERC20("Forest Token", "FOREST") SellTax(_taxReceiver) {
        _mint(msg.sender, _totalSupply * 10 ** 18);
    }

    function setTaxRequirement(bool _newState) external onlyOwner {
        disableTaxRequirement = _newState;
    }

    /**
     * @dev Overrides default ERC20 transferFrom to implement SellTax functionality.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        bool taxRequired = false;

        if ( disableTaxRequirement != true ) taxRequired = requiresTax(to);

        if ( taxRequired ) {
            uint256 taxedAmount = calculateTaxAmount(amount);

            _spendAllowance(from, spender, amount);

            _transfer(from, taxReceiver, taxedAmount);
            _transfer(from, to, amount.sub(taxedAmount));

            emit TransferFromWithTax(taxPercentage);
        } else {
            _spendAllowance(from, spender, amount);
            _transfer(from, to, amount);
        }

        return true;
    }

    /**
     * @dev Overrides default ERC20 transfer to implement SellTax functionality.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        bool taxRequired = false;

        if ( disableTaxRequirement != true ) taxRequired = requiresTax(to);

        if ( taxRequired ) {
            uint256 taxedAmount = calculateTaxAmount(amount);

            _transfer(owner, taxReceiver, taxedAmount);
            _transfer(owner, to, amount.sub(taxedAmount));

            emit TransferWithTax(taxPercentage);
        } else {
            _transfer(owner, to, amount);
        }

        return true;
    }
}