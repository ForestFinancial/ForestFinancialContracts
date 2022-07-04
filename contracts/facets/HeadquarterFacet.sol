// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/******************************************************************************\
*
* @author Forest Financial Team
* @title Facet for Headquarters
*
/******************************************************************************/

import "../libraries/LibProtocolMeta.sol";
import "../libraries/LibHeadquarter.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract HeadquarterFacet is ReentrancyGuard {

    modifier notBlacklisted() {
        LibProtocolMeta.DiamondStorage storage ds = LibProtocolMeta.diamondStorage();

        require(ds.blacklisted[LibProtocolMeta.msgSender()] != true, "FOREST: Address is blacklisted");
        _;
    }

    modifier doesNotExceedMaxBalance() {
        LibHeadquarter.DiamondStorage storage ds = LibHeadquarter.diamondStorage();

        require(getHeadquarterBalance(LibProtocolMeta.msgSender()) < ds.headquartersMetadata.maxBalance, "FOREST: Address has already reached max Headquarter balance");
        _;
    }

    modifier ownsHeadquarter(uint256 _headquarterId) {
        LibHeadquarter.DiamondStorage storage ds = LibHeadquarter.diamondStorage();

        require(LibProtocolMeta.msgSender() == ds.headquarters[_headquarterId].owner, "FOREST: Caller is not owner of headquarter");
        _;
    }

    modifier isUpgradeable(uint256 _headquarterId) {
        LibHeadquarter.DiamondStorage storage ds = LibHeadquarter.diamondStorage();

        require(ds.headquarters[_headquarterId].level < ds.headquartersMetadata.maxLevel);
        _;
    }

    /******************************************************************************\
    * @dev Public function for minting a headquarter.
    /******************************************************************************/
    function mintHeadquarter(string memory _continent) 
        public
        notBlacklisted
        doesNotExceedMaxBalance
        nonReentrant
        returns (uint256) 
    {
        // First check if address already has a Headquarter. If so, the first HQ is free of charge
        if (getHeadquarterBalance(LibProtocolMeta.msgSender()) < 1) {
            return LibHeadquarter._mintHeadquarter(LibProtocolMeta.msgSender(), _continent);
        } else {
            LibProtocolMeta.DiamondStorage storage PMds = LibProtocolMeta.diamondStorage();

            uint256 forestTokenPrice = LibHeadquarter._calculatePrice(LibProtocolMeta.msgSender());

            require(PMds.forestToken.balanceOf(LibProtocolMeta.msgSender()) > forestTokenPrice, "FOREST: Insufficient forest balance");
            require(PMds.forestToken.allowance(LibProtocolMeta.msgSender(), address(this)) > forestTokenPrice, "FOREST: Insufficient allowance");

            PMds.forestToken.transferFrom(
                LibProtocolMeta.msgSender(),
                PMds.rewardPool,
                forestTokenPrice
            );

            return LibHeadquarter._mintHeadquarter(LibProtocolMeta.msgSender(), _continent);
        }
    }

    function upgradeHeadquarter(uint256 _headquarterId) 
        public
        notBlacklisted
        nonReentrant
        ownsHeadquarter(_headquarterId)
        isUpgradeable(_headquarterId)
    {
        LibProtocolMeta.DiamondStorage storage PMds = LibProtocolMeta.diamondStorage();

        uint256 forestTokenPrice = LibHeadquarter._calculatePrice(LibProtocolMeta.msgSender());

        require(PMds.forestToken.balanceOf(LibProtocolMeta.msgSender()) > forestTokenPrice, "FOREST: Insufficient forest balance");
        require(PMds.forestToken.allowance(LibProtocolMeta.msgSender(), address(this)) > forestTokenPrice, "FOREST: Insufficient allowance");

        PMds.forestToken.transferFrom(
            LibProtocolMeta.msgSender(),
            PMds.rewardPool,
            forestTokenPrice
        );

        LibHeadquarter._upgradeHeadquarter(_headquarterId);
    }

    function getHeadquarterForestPrice(address _for) public view returns(uint256) {
        return LibHeadquarter._calculatePrice(_for);
    }

    function getMaxYieldTreeCapacityOf(address _of) public view returns(uint256) {
        return LibHeadquarter._getMaxYieldTreeCapacityOf(_of);
    }

    /******************************************************************************\
    * @dev Returns YieldTree balance of specific address
    /******************************************************************************/
    function getHeadquarterBalance(address _of) public view returns(uint256) {
        LibHeadquarter.DiamondStorage storage ds = LibHeadquarter.diamondStorage();
        uint256[] memory headquarters = ds.headquartersOf[_of];

        return headquarters.length;
    }

    /******************************************************************************\
    * @dev Returns all Headquarter id's of specific address
    /******************************************************************************/
    function getHeadquartersOf(address _of) public view returns(uint256[] memory) {
        LibHeadquarter.DiamondStorage storage ds = LibHeadquarter.diamondStorage();
        uint256[] memory headquarters = ds.headquartersOf[_of];

        return headquarters;
    }

    /******************************************************************************\
    * @dev Returns Headquarter with given id
    /******************************************************************************/
    function getHeadquarter(uint256 _id) public view returns(LibHeadquarter.Headquarter memory) {
        LibHeadquarter.DiamondStorage storage ds = LibHeadquarter.diamondStorage();
        LibHeadquarter.Headquarter memory headquarter = ds.headquarters[_id];

        return headquarter;
    }
} 