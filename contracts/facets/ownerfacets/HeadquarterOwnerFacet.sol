// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/******************************************************************************\
*
* @author Forest Financial Team
* @title Facet for protocol ownership
*
/******************************************************************************/

import "../../libraries/LibDiamond.sol";
import "../../libraries/LibHeadquarter.sol";
import "../../libraries/LibProtocolMeta.sol";

contract HeadquarterOwnerFacet {
    modifier onlyOwner() {
        require(LibProtocolMeta.msgSender() == LibDiamond.contractOwner());
        _;
    }

    function initHeadquarters(
        uint8 _maxBalance,
        uint8 _maxLevel,
        uint8 _maxYieldTreesPerLevel,
        uint256 _forestPrice
    ) external onlyOwner {
        LibHeadquarter.DiamondStorage storage HQds = LibHeadquarter.diamondStorage();

        HQds.headquartersMetadata.maxBalance = _maxBalance;
        HQds.headquartersMetadata.maxLevel = _maxLevel;
        HQds.headquartersMetadata.maxYieldTreesPerLevel = _maxYieldTreesPerLevel;
        HQds.headquartersMetadata.forestPrice = _forestPrice;
    }

    function setHeadquartersMaxBalance(uint8 _newMaxBalance) external onlyOwner {
        LibHeadquarter.DiamondStorage storage HQds = LibHeadquarter.diamondStorage();
        HQds.headquartersMetadata.maxBalance = _newMaxBalance;
    }

    function setHeadquartersMaxLevel(uint8 _newMaxLevel) external onlyOwner {
        LibHeadquarter.DiamondStorage storage HQds = LibHeadquarter.diamondStorage();
        HQds.headquartersMetadata.maxLevel = _newMaxLevel;
    }

    function setHeadquartersMaxYieldTreesPerLevel(uint8 _newMaxYieldTreesPerLevel) external onlyOwner {
        LibHeadquarter.DiamondStorage storage HQds = LibHeadquarter.diamondStorage();
        HQds.headquartersMetadata.maxYieldTreesPerLevel = _newMaxYieldTreesPerLevel;
    }

    function setHeadquartersForestPrice(uint256 _newForestPrice) external onlyOwner {
        LibHeadquarter.DiamondStorage storage HQds = LibHeadquarter.diamondStorage();
        HQds.headquartersMetadata.forestPrice = _newForestPrice;
    }

}