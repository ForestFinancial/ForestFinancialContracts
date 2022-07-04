// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/******************************************************************************\
*
* @author Forest Financial Team
* @title Library the foresterNFTs
*
/******************************************************************************/

import "../interfaces/IERC721.sol";
import "../libraries/LibProtocolMeta.sol";
import "../libraries/LibYieldTree.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

library LibForesterNFT {
    struct ForesterNFT {
        uint256 yieldtreeId;
        uint256 experience;
        uint32 creationTime;
    }

    struct DiamondStorage {
        mapping(uint256 => ForesterNFT) foresters;
        uint8 maxProductivity;
        uint32 maxLevel;
        uint256 forestBoostPerLevel;  
        uint8 baseExperiencePerDay;    
    }

    function _mintForesterNFT(uint256 _yieldtreeId) internal returns(uint256) {
        LibProtocolMeta.DiamondStorage storage PMds = LibProtocolMeta.diamondStorage();
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();
        LibForesterNFT.DiamondStorage storage FNFTds = LibForesterNFT.diamondStorage();

        uint256 tokenId = PMds.foresterNFT.safeMint(YTds.yieldtrees[_yieldtreeId].owner);

        ForesterNFT memory newForesterNFT;
        newForesterNFT.yieldtreeId = _yieldtreeId;
        newForesterNFT.experience = 0;
        newForesterNFT.creationTime = uint32(block.timestamp);

        FNFTds.foresters[tokenId] = newForesterNFT;

        return tokenId;
    }

    function _attachForesterNFT(uint256 _yieldtreeId, uint256 _foresterId) internal {
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();
        LibForesterNFT.DiamondStorage storage FNFTds = LibForesterNFT.diamondStorage();

        LibYieldTree.YieldTree storage yieldtree = YTds.yieldtrees[_yieldtreeId];
        ForesterNFT storage forester = FNFTds.foresters[_foresterId];

        yieldtree.foresterId = _foresterId;
        forester.yieldtreeId = _yieldtreeId;
    }

    function _detachForesterNFT(uint256 _yieldtreeId) internal {
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();
        LibForesterNFT.DiamondStorage storage FNFTds = LibForesterNFT.diamondStorage();

        LibYieldTree.YieldTree storage yieldtree = YTds.yieldtrees[_yieldtreeId];
        ForesterNFT storage forester = FNFTds.foresters[yieldtree.foresterId];

        yieldtree.foresterId = 0;
        forester.yieldtreeId = 0;
    }

    function _getForesterProductivity(uint256 _foresterId) internal view returns(uint256) {
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();
        LibForesterNFT.DiamondStorage storage FNFTds = LibForesterNFT.diamondStorage();

        ForesterNFT memory forester = FNFTds.foresters[_foresterId];

        uint32 lastClaimTime = YTds.yieldtrees[forester.yieldtreeId].lastClaimTime;
        uint256 productivity = (block.timestamp - lastClaimTime) / 60 / 60 / 24;

        if (productivity > FNFTds.maxProductivity) productivity = FNFTds.maxProductivity;

        return productivity;
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