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
import "../../libraries/LibCoreNFT.sol";

contract coreNFTManageFacet {
    modifier onlyOwner() {
        require(LibProtocolMetaData._msgSender() == LibDiamond.contractOwner(), "FOREST: Caller is not the owner");
        _;
    }

    function initCoreNFT(
        uint256 _seedNFTBoost,
        uint256 _saplingNFTBoost,
        uint256 _treeNFTBoost,
        uint256 _peltonNFTBoost
    ) external onlyOwner {
        LibCoreNFT.DiamondStorage storage CNFTds = LibCoreNFT.diamondStorage();

        CNFTds.seedNFTBoost = _seedNFTBoost;
        CNFTds.saplingNFTBoost = _saplingNFTBoost;
        CNFTds.treeNFTBoost = _treeNFTBoost;
        CNFTds.peltonNFTBoost = _peltonNFTBoost;
    }

    function setSeedNFTBoost(uint256 _seedNFTBoost) external onlyOwner {
        LibCoreNFT.DiamondStorage storage CNFTds = LibCoreNFT.diamondStorage();
        CNFTds.seedNFTBoost = _seedNFTBoost;
    }

    function setSaplingNFTBoost(uint256 _saplingNFTBoost) external onlyOwner {
        LibCoreNFT.DiamondStorage storage CNFTds = LibCoreNFT.diamondStorage();
        CNFTds.saplingNFTBoost = _saplingNFTBoost;
    }

    function setTreeNFTBoost(uint256 _treeNFTBoost) external onlyOwner {
        LibCoreNFT.DiamondStorage storage CNFTds = LibCoreNFT.diamondStorage();
        CNFTds.treeNFTBoost = _treeNFTBoost;
    }

    function setPeltonNFTBoost(uint256 _peltonNFTBoost) external onlyOwner {
        LibCoreNFT.DiamondStorage storage CNFTds = LibCoreNFT.diamondStorage();
        CNFTds.peltonNFTBoost = _peltonNFTBoost;
    }
}