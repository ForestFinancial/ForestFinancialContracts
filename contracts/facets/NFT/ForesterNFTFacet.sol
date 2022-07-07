// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/******************************************************************************\
*
* @author Forest Financial Team
* @title Responsible for foresterNFTs on the YieldTrees
*
/******************************************************************************/

import "../../interfaces/IERC721.sol";
import "../../libraries/LibProtocolMetaData.sol";
import "../../libraries/LibYieldTree.sol";
import "../../libraries/LibForesterNFT.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ForesterNFTFacet is ReentrancyGuard {
    modifier notBlacklisted() {
        LibProtocolMetaData.DiamondStorage storage ds = LibProtocolMetaData.diamondStorage();
        require(ds.blacklisted[LibProtocolMetaData._msgSender()] != true, "FOREST: Address is blacklisted");
        _;
    }

    modifier ownsYieldTree(uint256 _yieldtreeId) {
        LibYieldTree.DiamondStorage storage ds = LibYieldTree.diamondStorage();
        require(LibProtocolMetaData._msgSender() == ds.yieldtrees[_yieldtreeId].owner, "FOREST: Caller is not owner of YieldTree");
        _;
    }

    /******************************************************************************\
    * @dev Checks if the Forester NFT the caller is trying to attach is still attached to a old YieldTree of another address
    /******************************************************************************/
    function foresterNFTOwnerCheck(uint256 _foresterId) internal {
        LibProtocolMetaData.DiamondStorage storage PMds = LibProtocolMetaData.diamondStorage();
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();
        LibForesterNFT.DiamondStorage storage FNFTds = LibForesterNFT.diamondStorage();

        LibForesterNFT.ForesterNFT memory forester = FNFTds.foresters[_foresterId];
        LibYieldTree.YieldTree memory yieldtree = YTds.yieldtrees[forester.yieldtreeId];

        if (yieldtree.owner != PMds.foresterNFT.ownerOf(_foresterId)) {
            LibForesterNFT._detachForesterNFT(forester.yieldtreeId);
        }
    }

    /******************************************************************************\
    * @dev Checks if the Forester NFT is already initialized in the storage
    /******************************************************************************/
    function checkForesterExistence(uint256 _foresterId) internal {
        LibForesterNFT.DiamondStorage storage FNFTds = LibForesterNFT.diamondStorage();
        if (FNFTds.foresters[_foresterId].creationTime == 0) FNFTds.foresters[_foresterId].creationTime = uint32(block.timestamp);
    }

    /******************************************************************************\
    * @dev Function for attaching a Forester NFT to a YieldTree
    /******************************************************************************/
    function attachForesterNFT(uint256 _yieldtreeId, uint256 _foresterId)
        public
        notBlacklisted
        ownsYieldTree(_yieldtreeId)
        nonReentrant
    {
        LibProtocolMetaData.DiamondStorage storage PMds = LibProtocolMetaData.diamondStorage();

        checkForesterExistence(_foresterId);
        foresterNFTOwnerCheck(_foresterId);
        require(doesYieldTreeHaveForesterNFTAttached(_yieldtreeId) != true, "FOREST: YieldTree already has an ForesterNFT attached");
        require(LibProtocolMetaData._msgSender() == PMds.foresterNFT.ownerOf(_foresterId), "FOREST: Caller is not the owner of given Forester token id");
        require(isForesterNFTActive(_foresterId) != true, "FOREST: ForesterNFT is already active pnm an YieldTree");

        LibYieldTree._takeRewardsSnapshot(_yieldtreeId);
        LibForesterNFT._attachForesterNFT(_yieldtreeId, _foresterId);
    }

    /******************************************************************************\
    * @dev Function for detaching a Forester NFT from a YieldTree
    /******************************************************************************/
    function detachForesterNFT(uint256 _yieldtreeId)
        public
        notBlacklisted
        ownsYieldTree(_yieldtreeId)
        nonReentrant
    {
        require(doesYieldTreeHaveForesterNFTAttached(_yieldtreeId) != false, "FOREST: YieldTree does not have an ForesterNFT attached");
        LibYieldTree._takeRewardsSnapshot(_yieldtreeId);
        LibForesterNFT._detachForesterNFT(_yieldtreeId);
    }

    /******************************************************************************\
    * @dev Returns whether given YieldTree has a Forester NFT attached
    /******************************************************************************/
    function doesYieldTreeHaveForesterNFTAttached(uint256 _yieldtreeId) internal view returns (bool) {
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();

        if (YTds.yieldtrees[_yieldtreeId].foresterId != 0) return true;

        return false;
    }

    /******************************************************************************\
    * @dev Returns whether given Forester NFT is attached to a YieldTree
    /******************************************************************************/
    function isForesterNFTActive(uint256 _foresterId) internal view returns (bool) {
        LibForesterNFT.DiamondStorage storage FNFTds = LibForesterNFT.diamondStorage();
        if (FNFTds.foresters[_foresterId].yieldtreeId != 0) return true;
        return false;
    }
} 