// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/******************************************************************************\
*
* @author Forest Financial Team
* @title Responsible for claiming on the YieldTrees
*
/******************************************************************************/

import "../../interfaces/IERC721.sol";
import "../../libraries/LibProtocolMetaData.sol";
import "../../libraries/LibYieldTree.sol";
import "../../libraries/LibHeadquarter.sol";
import "../../libraries/LibRoots.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract YieldTreeClaimFacet is ReentrancyGuard {
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

    modifier hasSpaceForYieldTree() {
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();
        LibHeadquarter.DiamondStorage storage HQds = LibHeadquarter.diamondStorage();

        require(YTds.yieldtreesOf[LibProtocolMetaData._msgSender()].length < LibHeadquarter._getMaxYieldTreeCapacityOf(LibProtocolMetaData._msgSender())
        ,
        "FOREST: No more space for a YieldTree");
        _;
    }

    /******************************************************************************\
    * @dev Function for claiming rewards of specific YieldTree
    /******************************************************************************/
    function claimRewardsOfYieldTree(uint256 _yieldtreeId, bool swapToRoots)
        public
        notBlacklisted
        ownsYieldTree(_yieldtreeId)
        nonReentrant
    {
        LibProtocolMetaData.DiamondStorage storage PMds = LibProtocolMetaData.diamondStorage();
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();
        LibYieldTree.YieldTree storage yieldtree = YTds.yieldtrees[_yieldtreeId];
        
        uint256 forestToReward = LibYieldTree._getRewardsOf(_yieldtreeId);

        if (swapToRoots == true) {
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
    }

    /******************************************************************************\
    * @dev Function for claiming rewards of all YieldTrees belonging to caller
    /******************************************************************************/
    function claimRewardsOfAllYieldTrees(bool swapToRoots)
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

        if (swapToRoots == true) {
            LibRoots._giveRootsBasedOnForest(LibProtocolMetaData._msgSender(), totalForestToReward);
        } else {
            PMds.forestToken.transferFrom(
                PMds.rewardPool,
                LibProtocolMetaData._msgSender(),
                totalForestToReward
            );
        }
    }

    /******************************************************************************\
    * @dev Function to compound rewards into a new YieldTree
    /******************************************************************************/
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

    /******************************************************************************\
    * @dev Returns the rewards of a specific YieldTree
    /******************************************************************************/
    function getYieldTreeRewards(uint256 _yieldtreeId) public view returns (uint256) {
        return LibYieldTree._getRewardsOf(_yieldtreeId);
    }

    /******************************************************************************\
    * @dev Returns the total rewards of given address
    /******************************************************************************/
    function getTotalYieldTreeRewards(address _of) public view returns (uint256) {
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();
        
        uint256[] memory ownedYieldTrees = YTds.yieldtreesOf[_of];
        uint256 totalForestRewards;

        for(uint i = 0; i < ownedYieldTrees.length; i++) totalForestRewards += LibYieldTree._getRewardsOf(ownedYieldTrees[i]);

        return totalForestRewards;
    }
} 