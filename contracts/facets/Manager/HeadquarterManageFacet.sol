// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/******************************************************************************\
*
* @author Forest Financial Team
* @title Facet for protocol ownership
*
/******************************************************************************/

import "../../libraries/LibDiamond.sol";
import "../../libraries/LibProtocolMetaData.sol";
import "../../libraries/LibHeadquarter.sol";

contract HeadquarterManageFacet {
    modifier onlyOwner() {
        require(LibProtocolMetaData._msgSender() == LibDiamond.contractOwner(), "FOREST: Caller is not the owner");
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

    function setHeadquartersMaxBalance(uint8 _maxBalance) external onlyOwner {
        LibHeadquarter.DiamondStorage storage HQds = LibHeadquarter.diamondStorage();
        HQds.headquartersMetadata.maxBalance = _maxBalance;
    }

    function setHeadquartersMaxLevel(uint8 _maxLevel) external onlyOwner {
        LibHeadquarter.DiamondStorage storage HQds = LibHeadquarter.diamondStorage();
        HQds.headquartersMetadata.maxLevel = _maxLevel;        
    }

    function setHeadquartersMaxYieldTreesPerLevel(uint8 _maxYieldTreesPerLevel) external onlyOwner {
        LibHeadquarter.DiamondStorage storage HQds = LibHeadquarter.diamondStorage();
        HQds.headquartersMetadata.maxYieldTreesPerLevel = _maxYieldTreesPerLevel;        
    }

    function setHeadquartersForestPrice(uint8 _forestPrice) external onlyOwner {
        LibHeadquarter.DiamondStorage storage HQds = LibHeadquarter.diamondStorage();
        HQds.headquartersMetadata.forestPrice = _forestPrice;        
    }
}