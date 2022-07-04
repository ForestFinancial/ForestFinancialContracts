// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/******************************************************************************\
*
* @author Forest Financial Team
* @title Responsible for claiming on the YieldTrees
*
/******************************************************************************/

import "../../interfaces/IERC721.sol";
import "../../libraries/LibProtocolMeta.sol";
import "../../libraries/LibYieldTree.sol";
import "../../libraries/LibHeadquarter.sol";
import "../../libraries/LibRoots.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract YieldTreeClaimFacet is ReentrancyGuard {
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

    modifier hasSpaceForYieldTree() {
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();
        LibHeadquarter.DiamondStorage storage HQds = LibHeadquarter.diamondStorage();

        require(YTds.yieldtreesOf[LibProtocolMeta.msgSender()].length < LibHeadquarter._getMaxYieldTreeCapacityOf(LibProtocolMeta.msgSender())
        ,
        "FOREST: No more space for a YieldTree");
        _;
    }

    function claimRewardsOfYieldTree(uint256 _yieldtreeId, bool swapToRoots)
        public
        notBlacklisted
        ownsYieldTree(_yieldtreeId)
        nonReentrant
    {
        LibProtocolMeta.DiamondStorage storage PMds = LibProtocolMeta.diamondStorage();
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();

        LibYieldTree.YieldTree storage yieldtree = YTds.yieldtrees[_yieldtreeId];
        
        uint256 forestToReward = LibYieldTree._getTotalRewardsOf(_yieldtreeId);

        if (swapToRoots == true) {
            LibRoots._giveRootsBasedOnForest(LibProtocolMeta.msgSender(), forestToReward);
        } else {
            PMds.forestToken.transferFrom(
                PMds.rewardPool,
                LibProtocolMeta.msgSender(),
                forestToReward
            );
        }

        LibYieldTree._resetRewardsSnapshot(_yieldtreeId);
        yieldtree.lastClaimTime = uint32(block.timestamp);
        yieldtree.totalClaimed += forestToReward;
    }

    function claimRewardsOfAllYieldTrees(bool swapToRoots)
        public
        notBlacklisted
        nonReentrant
    {
        LibProtocolMeta.DiamondStorage storage PMds = LibProtocolMeta.diamondStorage();
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();
        
        uint256[] memory ownedYieldTrees = YTds.yieldtreesOf[LibProtocolMeta.msgSender()];

        uint256 totalForestToReward;

        for(uint i = 0; i < ownedYieldTrees.length; i++){
            LibYieldTree.YieldTree storage yieldtree = YTds.yieldtrees[ownedYieldTrees[i]];

            uint256 forestToReward = LibYieldTree._getTotalRewardsOf(ownedYieldTrees[i]);

            LibYieldTree._resetRewardsSnapshot(ownedYieldTrees[i]);
            yieldtree.lastClaimTime = uint32(block.timestamp);
            yieldtree.totalClaimed += forestToReward;
            totalForestToReward += forestToReward;
        }

        if (swapToRoots == true) {
            LibRoots._giveRootsBasedOnForest(LibProtocolMeta.msgSender(), totalForestToReward);
        } else {
            PMds.forestToken.transferFrom(
                PMds.rewardPool,
                LibProtocolMeta.msgSender(),
                totalForestToReward
            );
        }
    }

    // function compoundRewardsIntoYieldTree()
    //     public
    //     notBlacklisted
    //     hasSpaceForYieldTree
    //     nonReentrant
    // {
    //     LibProtocolMeta.DiamondStorage storage PMds = LibProtocolMeta.diamondStorage();
    //     LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();
    //     LibHeadquarter.DiamondStorage storage HQds = LibHeadquarter.diamondStorage();
    //     LibYieldTree.PaymentDistribution memory paymentDistribution = YTds.paymentDistributionData;

    //     uint256[] memory ownedYieldTrees = YTds.yieldtreesOf[LibProtocolMeta.msgSender()];
    //     uint256[] memory ownedHeadquarters = HQds.headquartersOf[LibProtocolMeta.msgSender()];

    //     uint256 totalRewards;

    //     for(uint i = 0; i < ownedYieldTrees.length; i++){
    //         totalRewards += LibYieldTree._getTotalRewardsOf(ownedYieldTrees[i]);
    //     }

    //     require(totalRewards >= YTds.yieldtreesMetadata.forestPrice, "FOREST: Caller does not have enough rewards in order to compound");

    //     uint256 rewardsUsed;

    //     for(uint i = 0; i < ownedYieldTrees.length; i++){
    //         LibYieldTree._takeRewardsSnapshot(ownedYieldTrees[i]);

    //         uint256 rewardsOfYieldTree = YTds.rewardSnapshots[ownedYieldTrees[i]].snapshottedRewards;

    //         if (rewardsUsed + rewardsOfYieldTree > YTds.yieldtreesMetadata.forestPrice) {
    //             uint256 rewardsUsedToFill = YTds.yieldtreesMetadata.forestPrice - rewardsUsed;
    //             rewardsUsed = YTds.yieldtreesMetadata.forestPrice;

    //             YTds.rewardSnapshots[ownedYieldTrees[i]].snapshottedRewards -= rewardsUsedToFill;
    //             YTds.rewardSnapshots[ownedYieldTrees[i]].snapshotTime = uint32(block.timestamp);

    //             break;
    //         } else {
    //             rewardsUsed += rewardsOfYieldTree;
    //             LibYieldTree._resetRewardsSnapshot(ownedYieldTrees[i]);
    //         }
    //     }

    //     for(uint i = 0; i < ownedHeadquarters.length; i++){
    //         uint256 maxSpace = HQds.headquarters[ownedHeadquarters[i]].level * HQds.headquartersMetadata.maxYieldTreesPerLevel;
    //         uint256 remainingSpace = maxSpace - HQds.headquarters[ownedHeadquarters[i]].yieldtrees.length;

    //         if (remainingSpace > 0) {
    //             LibYieldTree._mintYieldTree(LibProtocolMeta.msgSender(),  ownedHeadquarters[i]);
    //             break;
    //         }
    //     }

    //     uint256 forestToTreasury = (LibYieldTree._getTokenPrice() / 100) * paymentDistribution.forestTreasuryPercentage;
    //     PMds.joeRouter.swapExactTokensForTokens(
    //         forestToTreasury,
    //         0,
    //         LibTokenData._getForestToWAVAXPath(),
    //         PMds.treasury,
    //         0
    //     );

    //     uint256 forestToLiquidity = (LibYieldTree._getTokenPrice() / 100) * paymentDistribution.forestLiquidityPercentage;
    //     uint256 etherToLiquidity = (LibYieldTree._getEtherPrice() / 100) * paymentDistribution.etherLiquidityPercentage;


    // }
} 