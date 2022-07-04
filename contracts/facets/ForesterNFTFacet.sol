// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/******************************************************************************\
*
* @author Forest Financial Team
* @title Responsible for foresterNFTs on the YieldTrees
*
/******************************************************************************/

import "../interfaces/IERC721.sol";
import "../libraries/LibYieldTree.sol";
import "../libraries/LibForesterNFT.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ForesterNFTFacet is ReentrancyGuard {
    modifier notBlacklisted() {
        LibProtocolMeta.DiamondStorage storage ds = LibProtocolMeta.diamondStorage();
        require(ds.blacklisted[LibProtocolMeta.msgSender()] != true, "FOREST: Address is blacklisted");
        _;
    }

    modifier ownsYieldTree(uint256 _yieldtreeId) {
        LibYieldTree.DiamondStorage storage ds = LibYieldTree.diamondStorage();
        require(LibProtocolMeta.msgSender() == ds.yieldtrees[_yieldtreeId].owner, "FOREST: Caller is not owner of YieldTree");
        _;
    }

    function doesYieldTreeHaveForesterNFTAttached(uint256 _yieldtreeId) internal view returns (bool) {
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();

        if (YTds.yieldtrees[_yieldtreeId].foresterId != 0) return true;

        return false;
    }

    function foresterNFTOwnerCheck(uint256 _foresterId) internal {
        LibProtocolMeta.DiamondStorage storage PMds = LibProtocolMeta.diamondStorage();
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();
        LibForesterNFT.DiamondStorage storage FNFTds = LibForesterNFT.diamondStorage();

        LibForesterNFT.ForesterNFT memory forester = FNFTds.foresters[_foresterId];
        LibYieldTree.YieldTree memory yieldtree = YTds.yieldtrees[forester.yieldtreeId];

        if (yieldtree.owner != PMds.foresterNFT.ownerOf(_foresterId)) {
            LibForesterNFT._detachForesterNFT(forester.yieldtreeId);
        }
    }

    function checkForesterExistence(uint256 _foresterId) internal {
        LibForesterNFT.DiamondStorage storage FNFTds = LibForesterNFT.diamondStorage();
        if (FNFTds.foresters[_foresterId].creationTime == 0) FNFTds.foresters[_foresterId].creationTime = uint32(block.timestamp);
    }

    function isForesterNFTActive(uint256 _foresterId) internal view returns (bool) {
        LibForesterNFT.DiamondStorage storage FNFTds = LibForesterNFT.diamondStorage();
        if (FNFTds.foresters[_foresterId].yieldtreeId != 0) return true;
        return false;
    }

    function attachForesterNFT(uint256 _yieldtreeId, uint256 _foresterId)
        public
        notBlacklisted
        ownsYieldTree(_yieldtreeId)
        nonReentrant
    {
        LibProtocolMeta.DiamondStorage storage PMds = LibProtocolMeta.diamondStorage();

        checkForesterExistence(_foresterId);
        foresterNFTOwnerCheck(_foresterId);
        require(doesYieldTreeHaveForesterNFTAttached(_yieldtreeId) != true, "FOREST: YieldTree already has an ForesterNFT attached");
        require(LibProtocolMeta.msgSender() == PMds.foresterNFT.ownerOf(_foresterId), "FOREST: Caller is not the owner of given Forester token id");
        require(isForesterNFTActive(_foresterId) != true, "FOREST: ForesterNFT is already active pnm an YieldTree");

        LibYieldTree._takeRewardsSnapshot(_yieldtreeId);
        LibForesterNFT._attachForesterNFT(_yieldtreeId, _foresterId);
    }

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
} 