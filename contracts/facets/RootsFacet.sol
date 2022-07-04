// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/******************************************************************************\
*
* @author Forest Financial Team
* @title Facet for Headquarters
*
/******************************************************************************/

import "../libraries/LibProtocolMeta.sol";
import "../libraries/LibTokenData.sol";
import "../libraries/LibRoots.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract RootsFacet is ReentrancyGuard {
    modifier notBlacklisted() {
        LibProtocolMeta.DiamondStorage storage ds = LibProtocolMeta.diamondStorage();

        require(ds.blacklisted[LibProtocolMeta.msgSender()] != true, "FOREST: Address is blacklisted");
        _;
    }

    /******************************************************************************\
    * @dev Swaps _amount of forest tokens to roots tokens. Roots tokens get minted
    /******************************************************************************/
    function swapForestToRoots(uint256 _amount)
        public
        notBlacklisted
        nonReentrant
    {
        LibProtocolMeta.DiamondStorage storage PMds = LibProtocolMeta.diamondStorage();

        require(_amount > 1000, "FOREST: Minimum swap of 0.000000000000001001 forest is required");
        require(PMds.forestToken.balanceOf(LibProtocolMeta.msgSender()) > _amount, "FOREST: Forest balance too low");
        require(PMds.forestToken.allowance(LibProtocolMeta.msgSender(), address(this)) > _amount, "FOREST: Allowance for forest is too low");

        PMds.forestToken.transferFrom(LibProtocolMeta.msgSender(), PMds.rewardPool, _amount);

        LibRoots._giveRootsBasedOnForest(LibProtocolMeta.msgSender(), _amount);
    }

    /******************************************************************************\
    * @dev Swaps roots tokens back to forest token. Roots tokens get burned
    /******************************************************************************/
    function swapRootsToForest(uint256 _amount)
        public
        notBlacklisted
        nonReentrant
    {
        LibProtocolMeta.DiamondStorage storage PMds = LibProtocolMeta.diamondStorage();

        require(_amount > 1000, "FOREST: Minimum swap of 0.000000000000001001 roots is required");
        require(PMds.rootsToken.balanceOf(LibProtocolMeta.msgSender()) > _amount, "FOREST: Roots balance too low");
        require(PMds.rootsToken.allowance(LibProtocolMeta.msgSender(), address(this)) > _amount, "FOREST: Allowance for roots is too low");

        LibRoots._giveForestBasedOnRoots(LibProtocolMeta.msgSender(), _amount);
    }
    
    function getRootsBackingPrice() public view returns (uint256) {
        return LibRoots._getBackingPrice();
    }

    function getRootsBuyPrice() public view returns (uint256) {
        return LibRoots._getRootsBuyPrice(LibProtocolMeta.msgSender());
    }

    function getRootsSellPrice() public view returns (uint256) {
        return LibRoots._getRootsSellPrice(LibProtocolMeta.msgSender());
    }

    function getRootsTreasuryBalance() public view returns (uint256) {
        return LibRoots._getRootsTreasuryBalance();
    }

    function getRootsSupply() public view returns (uint256) {
        return LibRoots._getRootsSupply();
    }
} 