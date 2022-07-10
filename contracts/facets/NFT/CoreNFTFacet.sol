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
import "../../libraries/LibCoreNFT.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract CoreNFTFacet is ReentrancyGuard {
    modifier notBlacklisted() {
        LibProtocolMetaData.DiamondStorage storage PMds = LibProtocolMetaData.diamondStorage();
        require(PMds.blacklisted[LibProtocolMetaData._msgSender()] != true, "FOREST: Address is blacklisted");
        _;
    }

    modifier ownsYieldTree(uint256 _yieldtreeId) {
        LibYieldTree.DiamondStorage storage ds = LibYieldTree.diamondStorage();
        require(LibProtocolMetaData._msgSender() == ds.yieldtrees[_yieldtreeId].owner, "FOREST: Caller is not owner of YieldTree");
        _;
    }

    /******************************************************************************\
    * @dev Checks if the CoreNFT the caller is trying to attach is still attached to a old YieldTree of another address
    /******************************************************************************/
    function coreNFTOwnerCheck(uint256 _coreNFTId, uint8 _type) internal {
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();

        IERC721 coreNFTContract = LibCoreNFT._getCoreNFTContract(_type);
        LibCoreNFT.CoreNFT memory coreNFT = LibCoreNFT._getCoreNFT(_coreNFTId, _type);
        LibYieldTree.YieldTree memory yieldtree = YTds.yieldtrees[coreNFT.yieldtreeId];

        if (yieldtree.owner != coreNFTContract.ownerOf(_coreNFTId)) {
            LibCoreNFT._detachCoreNFT(coreNFT.yieldtreeId);
        }
    }

    /******************************************************************************\
    * @dev Function for attaching a CoreNFT to a YieldTree
    /******************************************************************************/
    function attachCoreNFT(uint256 _yieldtreeId, uint256 _coreNFTId, uint8 _type)
        public
        notBlacklisted
        ownsYieldTree(_yieldtreeId)
        nonReentrant
    {
        coreNFTOwnerCheck(_coreNFTId, _type);
        require(doesYieldTreeHaveCoreNFTAttached(_yieldtreeId) != true, "FOREST: YieldTree already has an CoreNFT attached");
        require(LibProtocolMetaData._msgSender() == LibCoreNFT._getCoreNFTContract(_type).ownerOf(_coreNFTId), "FOREST: Caller is not the owner of given CoreNFT token id");
        require(isCoreNFTActive(_coreNFTId, _type) != true, "FOREST: CoreNFT is already active on an YieldTree");

        LibYieldTree._takeRewardsSnapshot(_yieldtreeId);
        LibCoreNFT._attachCoreNFT(_yieldtreeId, _coreNFTId, _type);
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
        require(doesYieldTreeHaveCoreNFTAttached(_yieldtreeId) != false, "FOREST: YieldTree does not have an CoreNFT attached");
        LibYieldTree._takeRewardsSnapshot(_yieldtreeId);
        LibCoreNFT._detachCoreNFT(_yieldtreeId);
    }

    /******************************************************************************\
    * @dev Returns whether given YieldTree has a coreNFT attached
    /******************************************************************************/
    function doesYieldTreeHaveCoreNFTAttached(uint256 _yieldtreeId) internal view returns (bool) {
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();

        if (YTds.yieldtrees[_yieldtreeId].coreNFTType != 0 && YTds.yieldtrees[_yieldtreeId].coreNFTId != 0) return true;

        return false;
    }

    /******************************************************************************\
    * @dev Returns whether given CoreNFT is attached to a YieldTree
    /******************************************************************************/
    function isCoreNFTActive(uint256 _coreNFTId, uint8 _type) internal view returns (bool) {
        if (LibCoreNFT._getCoreNFT(_coreNFTId, _type).yieldtreeId != 0) return true;
        return false;
    }

    /******************************************************************************\
    * @dev Returns CoreNFT with given details
    /******************************************************************************/
    function getCoreNFT(uint256 _coreNFTId, uint8 _type) public view returns (LibCoreNFT.CoreNFT memory) {
        return LibCoreNFT._getCoreNFT(_coreNFTId, _type);
    }

    /******************************************************************************\
    * @dev Returns CoreNFT boost amount
    /******************************************************************************/
    function getCoreNFTBoost(uint8 _type) internal view returns (uint256) {
        return LibCoreNFT._getCoreNFTBoost(_type);
    }
} 