// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/******************************************************************************\
*
* @author Forest Financial Team
* @title Responsible for claiming on the YieldTrees
*
/******************************************************************************/

import "../../libraries/LibProtocolMetaData.sol";
import "../../libraries/LibYieldTree.sol";
import "../../libraries/LibHeadquarter.sol";
import "../../libraries/LibRoots.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract YieldTreeClaimFacet is ReentrancyGuard {
    event YieldTreeRewardsClaimed(uint256 indexed _yieldtreeId, bool indexed _swappedToRoots);
    event AllYieldTreeRewardsClaimed(address indexed _for, bool indexed _swappedToRoots);

    modifier notBlacklisted() {
        LibProtocolMetaData.DiamondStorage storage PMds = LibProtocolMetaData.diamondStorage();
        require(PMds.blacklisted[LibProtocolMetaData._msgSender()] != true, "FOREST: Address is blacklisted");
        _;
    }

    modifier ownsYieldTree(uint256 _yieldtreeId) {
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();
        require(LibProtocolMetaData._msgSender() == YTds.yieldtrees[_yieldtreeId].owner, "FOREST: Caller is not owner of YieldTree");
        _;
    }

    /******************************************************************************\
    * @dev Function for claiming rewards of specific YieldTree
    /******************************************************************************/
    function claimRewardsOfYieldTree(uint256 _yieldtreeId, bool _swapToRoots)
        public
        notBlacklisted
        ownsYieldTree(_yieldtreeId)
        nonReentrant
    {
        LibProtocolMetaData.DiamondStorage storage PMds = LibProtocolMetaData.diamondStorage();
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();
        LibYieldTree.YieldTree storage yieldtree = YTds.yieldtrees[_yieldtreeId];
        
        uint256 forestToReward = LibYieldTree._getRewardsOf(_yieldtreeId);

        if (_swapToRoots == true) {
            LibRoots._giveRootsBasedOnForest(LibProtocolMetaData._msgSender(), forestToReward);
        } else {
            PMds.forestToken.transferFrom(
                PMds.rewardPool,
                LibProtocolMetaData._msgSender(),
                forestToReward
            );
        }

        LibYieldTree._resetRewardsSnapshot(_yieldtreeId);
        yieldtree.lastClaimTime = uint32(block.timestamp);
        yieldtree.totalClaimed += forestToReward;

        emit YieldTreeRewardsClaimed(_yieldtreeId, _swapToRoots);
    }

    /******************************************************************************\
    * @dev Function for claiming rewards of all YieldTrees belonging to caller
    /******************************************************************************/
    function claimRewardsOfAllYieldTrees(bool _swapToRoots)
        public
        notBlacklisted
        nonReentrant
    {
        LibProtocolMetaData.DiamondStorage storage PMds = LibProtocolMetaData.diamondStorage();
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();
        
        uint256[] memory ownedYieldTrees = YTds.yieldtreesOf[LibProtocolMetaData._msgSender()];

        uint256 totalForestToReward;

        for(uint i = 0; i < ownedYieldTrees.length; i++){
            LibYieldTree.YieldTree storage yieldtree = YTds.yieldtrees[ownedYieldTrees[i]];

            uint256 forestToReward = LibYieldTree._getRewardsOf(ownedYieldTrees[i]);

            LibYieldTree._resetRewardsSnapshot(ownedYieldTrees[i]);
            yieldtree.lastClaimTime = uint32(block.timestamp);
            yieldtree.totalClaimed += forestToReward;
            totalForestToReward += forestToReward;
        }

        if (_swapToRoots == true) {
            LibRoots._giveRootsBasedOnForest(LibProtocolMetaData._msgSender(), totalForestToReward);
        } else {
            PMds.forestToken.transferFrom(
                PMds.rewardPool,
                LibProtocolMetaData._msgSender(),
                totalForestToReward
            );
        }

        emit AllYieldTreeRewardsClaimed(LibProtocolMetaData._msgSender(), _swapToRoots);
    }
} 