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
import "../../libraries/LibForesterNFT.sol";

contract ForesterNFTManageFacet {
    modifier onlyOwner() {
        require(LibProtocolMetaData._msgSender() == LibDiamond.contractOwner(), "FOREST: Caller is not the owner");
        _;
    }

    function initForesterNFT(
        uint8 _maxProductivity,
        uint32 _maxLevel,
        uint256 _forestBoostPerLevel,
        uint8 _baseExperiencePerDay 
    ) external onlyOwner {
        LibForesterNFT.DiamondStorage storage FNFTds = LibForesterNFT.diamondStorage();

        FNFTds.maxProductivity = _maxProductivity;
        FNFTds.maxLevel = _maxLevel;
        FNFTds.forestBoostPerLevel = _forestBoostPerLevel;
        FNFTds.baseExperiencePerDay = _baseExperiencePerDay;
    }

    function setForesterNFTMaxProductivity(uint8 _maxProductivity) external onlyOwner {
        LibForesterNFT.DiamondStorage storage FNFTds = LibForesterNFT.diamondStorage();
        FNFTds.maxProductivity = _maxProductivity;
    }

    function setForesterNFTMaxLevel(uint32 _maxLevel) external onlyOwner {
        LibForesterNFT.DiamondStorage storage FNFTds = LibForesterNFT.diamondStorage();
        FNFTds.maxLevel = _maxLevel;
    }

    function setForesterNFTForestBoosPerLevel(uint256 _forestBoostPerLevel) external onlyOwner {
        LibForesterNFT.DiamondStorage storage FNFTds = LibForesterNFT.diamondStorage();
        FNFTds.forestBoostPerLevel = _forestBoostPerLevel;       
    }

    function setForesterNFTBaseExperiencePerDay(uint8 _baseExperiencePerDay) external onlyOwner {
        LibForesterNFT.DiamondStorage storage FNFTds = LibForesterNFT.diamondStorage();
        FNFTds.baseExperiencePerDay = _baseExperiencePerDay;        
    }
}