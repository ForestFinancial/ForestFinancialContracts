// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/******************************************************************************\
*
* @author Forest Financial Team
* @title Library the foresterNFTs
*
/******************************************************************************/

import "../interfaces/IERC721.sol";
import "../libraries/LibProtocolMetaData.sol";
import "../libraries/LibYieldTree.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

library LibCoreNFT {
    struct CoreNFT {
        uint256 yieldtreeId;
    }

    struct DiamondStorage {
        mapping(uint256 => CoreNFT) seedNFTs;
        mapping(uint256 => CoreNFT) saplingNFTs;
        mapping(uint256 => CoreNFT) treeNFTs;
        mapping(uint256 => CoreNFT) peltonNFTs;
        uint256 seedNFTBoost;
        uint256 saplingNFTBoost;
        uint256 treeNFTBoost;
        uint256 peltonNFTBoost;
    }

    function _attachCoreNFT(uint256 _yieldtreeId, uint256 _coreNFTId, uint8 _type) internal {
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();

        LibYieldTree.YieldTree storage yieldtree = YTds.yieldtrees[_yieldtreeId];
        CoreNFT storage coreNFT = _getCoreNFT(yieldtree.coreNFTId, yieldtree.coreNFTType);

        yieldtree.coreNFTType = _type;
        yieldtree.coreNFTId = _coreNFTId;
        coreNFT.yieldtreeId = _yieldtreeId;
    }

    function _detachCoreNFT(uint256 _yieldtreeId) internal {
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();

        LibYieldTree.YieldTree storage yieldtree = YTds.yieldtrees[_yieldtreeId];
        CoreNFT storage coreNFT = _getCoreNFT(yieldtree.coreNFTId, yieldtree.coreNFTType);

        yieldtree.coreNFTType = 0;
        yieldtree.coreNFTId = 0;
        coreNFT.yieldtreeId = 0;
    }

    function _getCoreNFT(uint256 _coreNFTId, uint8 _type) internal view returns (CoreNFT storage) {
        LibCoreNFT.DiamondStorage storage CNFTds = LibCoreNFT.diamondStorage();
        if (_type == 1) return CNFTds.seedNFTs[_coreNFTId];
        else if (_type == 2) return CNFTds.saplingNFTs[_coreNFTId];
        else if (_type == 3) return CNFTds.treeNFTs[_coreNFTId];
        else if (_type == 4) return CNFTds.peltonNFTs[_coreNFTId];
        else revert("FOREST: Could not get CoreNFT"); 
    }

    function _getCoreNFTContract(uint8 _type) internal view returns (IERC721) {
        LibProtocolMetaData.DiamondStorage storage PMds = LibProtocolMetaData.diamondStorage();
        if (_type == 1) return PMds.seedNFT;
        else if (_type == 2) return PMds.saplingNFT;
        else if (_type == 3) return PMds.treeNFT;
        else if (_type == 4) return PMds.peltonNFT;
        else revert("FOREST: Could not get CoreNFT contract"); 
    }

    function _getCoreNFTBoost(uint8 _type) internal view returns (uint256) {
        LibCoreNFT.DiamondStorage storage CNFTds = LibCoreNFT.diamondStorage();
        if (_type == 1) return CNFTds.seedNFTBoost;
        else if (_type == 2) return CNFTds.saplingNFTBoost;
        else if (_type == 3) return CNFTds.treeNFTBoost;
        else if (_type == 4) return CNFTds.peltonNFTBoost;
        else revert("FOREST: Could not get CoreNFT boost");         
    }

    // Returns the struct from a specified position in contract storage
    // ds is short for DiamondStorage
    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        // Specifies a random position in contract storage
        bytes32 storagePosition = keccak256("diamond.storage.LibForesterNFT");
        // Set the position of our struct in contract storage
        assembly {
            ds.slot := storagePosition
        }
    }
}