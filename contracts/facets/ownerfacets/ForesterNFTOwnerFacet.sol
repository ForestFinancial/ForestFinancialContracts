// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/******************************************************************************\
*
* @author Forest Financial Team
* @title Facet for protocol ownership
*
/******************************************************************************/

import "../../libraries/LibDiamond.sol";
import "../../libraries/LibProtocolMeta.sol";
import "../../libraries/LibForesterNFT.sol";

contract ForesterNFTOwnerFacet {
    modifier onlyOwner() {
        require(LibProtocolMeta.msgSender() == LibDiamond.contractOwner());
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

    function setForesterMaxProductivity(uint8 _newMaxProductivity) external onlyOwner {
        LibForesterNFT.DiamondStorage storage FNFTds = LibForesterNFT.diamondStorage();
        FNFTds.maxProductivity = _newMaxProductivity;
    }

    function setForesterMaxLevel(uint8 _newMaxLevel) external onlyOwner {
        LibForesterNFT.DiamondStorage storage FNFTds = LibForesterNFT.diamondStorage();
        FNFTds.maxLevel = _newMaxLevel;
    }

    function setForesterForestBoostPerLevel(uint8 _newForestBoostPerLevel) external onlyOwner {
        LibForesterNFT.DiamondStorage storage FNFTds = LibForesterNFT.diamondStorage();
        FNFTds.forestBoostPerLevel = _newForestBoostPerLevel;
    }

    function setBaseExperiencePerDay(uint8 _newBaseExperiencePerDay) external onlyOwner {
        LibForesterNFT.DiamondStorage storage FNFTds = LibForesterNFT.diamondStorage();
        FNFTds.baseExperiencePerDay = _newBaseExperiencePerDay;
    }
}