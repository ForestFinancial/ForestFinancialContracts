// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/******************************************************************************\
*
* @author Forest Financial Team
* @title SellTax for ERC20 token
*
/******************************************************************************/

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract SellTax is Ownable {
    using SafeMath for uint256;

    uint256 public taxPercentage;
    address public taxReceiver;

    mapping(address => bool) public taxAddresses;
    mapping(address => bool) public excludedFromTax;

    event TaxPercentageSet(uint256 _newTax);
    event TaxReceiverSet(address _newTaxReceiver);
    event TaxAddressSet(address _taxAddress, bool _newState);
    event TaxExclusionSet(address _address, bool _newState);

    constructor (address _taxReceiver) {
        taxReceiver = _taxReceiver;
    }

    /**
     * @dev Sets the tax percentage.
     *
     * - A hardcoded maximum of 50 percent is set for safety, meaning this contract can never take all the tokens of a transfer.
     */
    function setTaxPercentage(uint256 _taxPercentage) external onlyOwner {
        require(_taxPercentage <= 50, "Selling tax not allowed to be higher than 50");

        taxPercentage = _taxPercentage;

        emit TaxPercentageSet(_taxPercentage);
    }

    /**
     * @dev Sets the address where the tax funds will go to.
     */
    function setTaxReceiver(address _taxReceiver) external onlyOwner {
        require(_taxReceiver != address(0), "Cannot set tax receiver to zero address");

        taxReceiver = _taxReceiver;

        emit TaxReceiverSet(_taxReceiver);
    }

    /**
     * @dev Updates or sets a address in the taxAddresses mapping. If set to true, tax has to be paid if sent to that address.
     */
    function setTaxAddress(address _address, bool _state) external onlyOwner {
        require(_address != address(0), "Cannot set tax address for zero address");

        taxAddresses[_address] = _state;

        emit TaxAddressSet(_address, _state);
    }

    /**
     * @dev Updates or sets a excluded address, these addresses do not have to pay tax.
     */
    function setExcludedAddress(address _address, bool _state) external onlyOwner {
        require(_address != address(0), "Cannot set exclusion for zero address");

        excludedFromTax[_address] = _state;

        emit TaxExclusionSet(_address, _state);
    }

    /**
     * @dev Returns amount of tax to be paid.
     */
    function calculateTaxAmount(uint256 _amount) public view returns (uint256) {
        ( , uint256 onePercent ) = _amount.tryDiv(100);
        ( , uint256 fullTax ) = onePercent.tryMul(taxPercentage);

        return fullTax;
    }

    /**
     * @dev Returns whether tax has to be paid when sending tokens to the _to address.
     */
    function requiresTax(address _to) public view returns (bool) {
        if (taxPercentage == 0 || msg.sender == owner() || excludedFromTax[_to] == true) return false;

        return taxAddresses[_to];
    }
}