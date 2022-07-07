// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/******************************************************************************\
*
* @author Forest Financial Team
* @title Facet for Roots
*
/******************************************************************************/

import "../../libraries/LibProtocolMetaData.sol";
import "../../libraries/LibTokenData.sol";
import "../../libraries/LibRoots.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract RootsFacet is ReentrancyGuard {
    modifier notBlacklisted() {
        LibProtocolMetaData.DiamondStorage storage ds = LibProtocolMetaData.diamondStorage();

        require(ds.blacklisted[LibProtocolMetaData._msgSender()] != true, "FOREST: Address is blacklisted");
        _;
    }

    /******************************************************************************\
    * @dev Function for swapping Forest to Roots tokens
    /******************************************************************************/
    function swapForestToRoots(uint256 _amount)
        public
        notBlacklisted
        nonReentrant
    {
        LibProtocolMetaData.DiamondStorage storage PMds = LibProtocolMetaData.diamondStorage();

        require(_amount > 1000, "FOREST: Minimum swap of 0.000000000000001001 forest is required");
        require(PMds.forestToken.balanceOf(LibProtocolMetaData._msgSender()) > _amount, "FOREST: Forest balance too low");
        require(PMds.forestToken.allowance(LibProtocolMetaData._msgSender(), address(this)) > _amount, "FOREST: Allowance for forest is too low");

        PMds.forestToken.transferFrom(LibProtocolMetaData._msgSender(), PMds.rewardPool, _amount);

        LibRoots._giveRootsBasedOnForest(LibProtocolMetaData._msgSender(), _amount);
    }

    /******************************************************************************\
    * @dev Function for swapping Roots to Forest tokens
    /******************************************************************************/
    function swapRootsToForest(uint256 _amount)
        public
        notBlacklisted
        nonReentrant
    {
        LibProtocolMetaData.DiamondStorage storage PMds = LibProtocolMetaData.diamondStorage();

        require(_amount > 1000, "FOREST: Minimum swap of 0.000000000000001001 roots is required");
        require(PMds.rootsToken.balanceOf(LibProtocolMetaData._msgSender()) > _amount, "FOREST: Roots balance too low");
        require(PMds.rootsToken.allowance(LibProtocolMetaData._msgSender(), address(this)) > _amount, "FOREST: Allowance for roots is too low");

        LibRoots._giveForestBasedOnRoots(LibProtocolMetaData._msgSender(), _amount);
    }

    /******************************************************************************\
    * @dev Returns the current growth factor
    /******************************************************************************/
    function getRootsGrowthFactor() public view returns (uint256) {
        return LibRoots._getGrowthFactor();
    }
    
    /******************************************************************************\
    * @dev Returns the current backing price
    /******************************************************************************/
    function getRootsBackingPrice() public view returns (uint256) {
        return LibRoots._getBackingPrice();
    }

    /******************************************************************************\
    * @dev Returns the current buy price
    /******************************************************************************/
    function getRootsBuyPrice() public view returns (uint256) {
        return LibRoots._getRootsBuyPrice();
    }

    /******************************************************************************\
    * @dev Returns the current sell price
    /******************************************************************************/
    function getRootsSellPrice() public view returns (uint256) {
        return LibRoots._getRootsSellPrice();
    }

    /******************************************************************************\
    * @dev Returns the treasury balance of Roots
    /******************************************************************************/
    function getRootsTreasuryBalance() public view returns (uint256) {
        return LibRoots._getRootsTreasuryBalance();
    }

    /******************************************************************************\
    * @dev Returns the total supply of Roots
    /******************************************************************************/
    function getRootsTotalSupply() public view returns (uint256) {
        return LibRoots._getRootsTotalSupply();
    }
} 