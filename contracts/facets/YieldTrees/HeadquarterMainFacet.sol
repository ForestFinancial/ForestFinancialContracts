// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/******************************************************************************\
*
* @author Forest Financial Team
* @title Facet for Headquarters
*
/******************************************************************************/

import "../../libraries/LibProtocolMetaData.sol";
import "../../libraries/LibHeadquarter.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract HeadquarterMainFacet is ReentrancyGuard {
    event HeadquarterMinted(address indexed _for, uint256 indexed _newHeadquarterId);
    event HeadquarterUpgraded(uint256 indexed _headquarterId);

    modifier notBlacklisted() {
        LibProtocolMetaData.DiamondStorage storage PMds = LibProtocolMetaData.diamondStorage();
        require(PMds.blacklisted[LibProtocolMetaData._msgSender()] != true, "FOREST: Caller is blacklisted");
        _;
    }

    modifier doesNotExceedMaxBalance() {
        LibHeadquarter.DiamondStorage storage HQds = LibHeadquarter.diamondStorage();
        require(getHeadquarterBalance(LibProtocolMetaData._msgSender()) < HQds.headquartersMetadata.maxBalance, "FOREST: Caller has already reached max Headquarter balance");
        _;
    }

    modifier ownsHeadquarter(uint256 _headquarterId) {
        LibHeadquarter.DiamondStorage storage HQds = LibHeadquarter.diamondStorage();
        require(LibProtocolMetaData._msgSender() == HQds.headquarters[_headquarterId].owner, "FOREST: Caller is not owner of Headquarter");
        _;
    }

    modifier isUpgradeable(uint256 _headquarterId) {
        LibHeadquarter.DiamondStorage storage HQds = LibHeadquarter.diamondStorage();
        require(HQds.headquarters[_headquarterId].level < HQds.headquartersMetadata.maxLevel, "FOREST: Cannot upgrade Headquarter, already on max level");
        _;
    }

    /******************************************************************************\
    * @dev Function for minting a new Headquarter
    /******************************************************************************/
    function mintHeadquarter(string memory _continent) 
        public
        notBlacklisted
        doesNotExceedMaxBalance
        nonReentrant
        returns (uint256) 
    {
        // First check if address already has a Headquarter. If so, the first HQ is free of charge
        if (getHeadquarterBalance(LibProtocolMetaData._msgSender()) < 1) {
            return LibHeadquarter._mintHeadquarter(LibProtocolMetaData._msgSender(), _continent);
        } else {
            LibProtocolMetaData.DiamondStorage storage PMds = LibProtocolMetaData.diamondStorage();

            uint256 forestTokenPrice = LibHeadquarter._getTokenPrice(LibProtocolMetaData._msgSender());

            require(PMds.forestToken.balanceOf(LibProtocolMetaData._msgSender()) > forestTokenPrice, "FOREST: Insufficient forest balance");
            require(PMds.forestToken.allowance(LibProtocolMetaData._msgSender(), address(this)) > forestTokenPrice, "FOREST: Insufficient allowance");

            PMds.forestToken.transferFrom(
                LibProtocolMetaData._msgSender(),
                PMds.rewardPool,
                forestTokenPrice
            );

            uint256 newHeadquarterId = LibHeadquarter._mintHeadquarter(LibProtocolMetaData._msgSender(), _continent);
            emit HeadquarterMinted(LibProtocolMetaData._msgSender(), newHeadquarterId);

            return newHeadquarterId;
        }
    }

    /******************************************************************************\
    * @dev Function for upgrading a existing Headquarter
    /******************************************************************************/
    function upgradeHeadquarter(uint256 _headquarterId) 
        public
        notBlacklisted
        nonReentrant
        ownsHeadquarter(_headquarterId)
        isUpgradeable(_headquarterId)
    {
        LibProtocolMetaData.DiamondStorage storage PMds = LibProtocolMetaData.diamondStorage();

        uint256 forestTokenPrice = LibHeadquarter._getTokenPrice(LibProtocolMetaData._msgSender());

        require(PMds.forestToken.balanceOf(LibProtocolMetaData._msgSender()) > forestTokenPrice, "FOREST: Insufficient forest balance");
        require(PMds.forestToken.allowance(LibProtocolMetaData._msgSender(), address(this)) > forestTokenPrice, "FOREST: Insufficient allowance");

        PMds.forestToken.transferFrom(
            LibProtocolMetaData._msgSender(),
            PMds.rewardPool,
            forestTokenPrice
        );

        LibHeadquarter._upgradeHeadquarter(_headquarterId);
        emit HeadquarterUpgraded(_headquarterId);
    }

    /******************************************************************************\
    * @dev Returns the total amount of headquarters in existence
    /******************************************************************************/
    function getTotalHeadquarters() public view returns(uint256) {
        LibProtocolMetaData.DiamondStorage storage PMds = LibProtocolMetaData.diamondStorage();
        return PMds.totalHeadquarters;
    }

    /******************************************************************************\
    * @dev Returns the next required Forest payment for buying or upgrading a Headquarter
    /******************************************************************************/
    function getHeadquarterForestPrice(address _for) public view returns(uint256) {
        return LibHeadquarter._getTokenPrice(_for);
    }

    /******************************************************************************\
    * @dev Returns the max YieldTree capacity of a specific address
    /******************************************************************************/
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
    * @dev Returns array of Headquarter id's of specific address
    /******************************************************************************/
    function getHeadquartersOf(address _of) public view returns(uint256[] memory) {
        LibHeadquarter.DiamondStorage storage ds = LibHeadquarter.diamondStorage();
        uint256[] memory headquarters = ds.headquartersOf[_of];

        return headquarters;
    }

    /******************************************************************************\
    * @dev Returns all Headquarter data of specific id
    /******************************************************************************/
    function getHeadquarter(uint256 _id) public view returns(LibHeadquarter.Headquarter memory) {
        LibHeadquarter.DiamondStorage storage ds = LibHeadquarter.diamondStorage();
        LibHeadquarter.Headquarter memory headquarter = ds.headquarters[_id];

        return headquarter;
    }
} 