// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/******************************************************************************\
*
* @author Forest Financial Team
* @title Responsible for compounding on the YieldTrees
*
/******************************************************************************/

import "../../libraries/LibProtocolMetaData.sol";
import "../../libraries/LibYieldTree.sol";
import "../../libraries/LibHeadquarter.sol";
import "../../libraries/LibRoots.sol";
import "../../libraries/LibLiquidityManager.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract YieldTreeCompoundFacet is ReentrancyGuard {
    event YieldTreeCompound(address indexed _for, uint256 indexed _newYieldTreeId);

    modifier notBlacklisted() {
        LibProtocolMetaData.DiamondStorage storage PMds = LibProtocolMetaData.diamondStorage();
        require(PMds.blacklisted[LibProtocolMetaData._msgSender()] != true, "FOREST: Address is blacklisted");
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
    * @dev Function to compound rewards into a new YieldTree
    /******************************************************************************/
    function distributeYieldTreeCompoundPayment() internal {
        LibProtocolMetaData.DiamondStorage storage PMds = LibProtocolMetaData.diamondStorage();
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();
        LibYieldTree.PaymentDistribution memory paymentDistribution = YTds.paymentDistributionData;

        uint256 forestAmount = (YTds.yieldtreesMetadata.forestPrice * (paymentDistribution.forestLiquidityPercentage * (1 * 10 ** PMds.forestToken.decimals()))) / (1 * 10 ** PMds.forestToken.decimals() + 2);
        uint256 toEtherAmount = (YTds.yieldtreesMetadata.forestPrice * (YTds.yieldtreesMetadata.percentageInEther * (1 * 10 ** PMds.forestToken.decimals()))) / (1 * 10 ** PMds.forestToken.decimals() + 2);

        PMds.forestToken.transferFrom(PMds.rewardPool, address(this), forestAmount + toEtherAmount);
        PMds.forestToken.approve(address(PMds.joeRouter), toEtherAmount);

        uint256[] memory toEtherSwap = PMds.joeRouter.swapExactTokensForTokens(
            toEtherAmount,
            0,
            LibTokenData._getForestToWAVAXPath(),
            address(this),
            block.timestamp
        );

        uint256 etherAmount = toEtherSwap[1];

        uint256 etherToTreasury = (etherAmount * (paymentDistribution.etherTreasuryPercentage * (1 * 10 ** PMds.forestToken.decimals()))) / (1 * 10 ** PMds.forestToken.decimals() + 2);
        uint256 etherToLiquidity = (etherAmount * (paymentDistribution.etherLiquidityPercentage * (1 * 10 ** PMds.forestToken.decimals()))) / (1 * 10 ** PMds.forestToken.decimals() + 2);

        payable(PMds.treasury).transfer(etherToTreasury);
        LibLiquidityManager._addLiquidity(etherToLiquidity, forestAmount);
    }

    /******************************************************************************\
    * @dev Function to compound rewards into a new YieldTree
    /******************************************************************************/
    function compoundRewardsIntoYieldTree()
        public
        notBlacklisted
        hasSpaceForYieldTree
        nonReentrant
    {
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();
        LibHeadquarter.DiamondStorage storage HQds = LibHeadquarter.diamondStorage();

        uint256[] memory ownedYieldTrees = YTds.yieldtreesOf[LibProtocolMetaData._msgSender()];
        uint256 totalClaimableRewards;

        for(uint i = 0; i < ownedYieldTrees.length; i++) totalClaimableRewards += LibYieldTree._getRewardsOf(ownedYieldTrees[i]);
        require(totalClaimableRewards >= YTds.yieldtreesMetadata.forestPrice, "FOREST: Rewards too low to compound");

        uint256 rewardsUsedToCompound;

        for(uint i = 0; i < ownedYieldTrees.length; i++) {
            LibYieldTree.YieldTree storage yieldtree = YTds.yieldtrees[ownedYieldTrees[i]];
            LibYieldTree.RewardSnapshotter storage rewardSnapshot = YTds.rewardSnapshots[ownedYieldTrees[i]];

            uint256 usableRewards = LibYieldTree._getRewardsOf(ownedYieldTrees[i]);

            if ((rewardsUsedToCompound + usableRewards) > YTds.yieldtreesMetadata.forestPrice) {
                usableRewards = YTds.yieldtreesMetadata.forestPrice - rewardsUsedToCompound;
                rewardsUsedToCompound += usableRewards;

                rewardSnapshot.snapshottedRewards -= usableRewards;
                rewardSnapshot.snapshotTime = uint32(block.timestamp);

                yieldtree.lastClaimTime = uint32(block.timestamp);
                yieldtree.totalClaimed += usableRewards;
            } else {
                rewardsUsedToCompound += usableRewards;
                LibYieldTree._resetRewardsSnapshot(ownedYieldTrees[i]);
                yieldtree.lastClaimTime = uint32(block.timestamp);
                yieldtree.totalClaimed += usableRewards;
            }
        }

        uint256[] memory ownedHeadquarters = HQds.headquartersOf[LibProtocolMetaData._msgSender()];
        uint256 targetHeadquarterId;

        for(uint i = 0; i < ownedHeadquarters.length; i++) {
            uint8 level = HQds.headquarters[ownedHeadquarters[i]].level;
            uint256 yieldtreeAmount = HQds.headquarters[ownedHeadquarters[i]].yieldtrees.length;

            if (yieldtreeAmount < (level * HQds.headquartersMetadata.maxYieldTreesPerLevel)) {
                targetHeadquarterId = ownedHeadquarters[i];
                break;
            }
        }

        if (targetHeadquarterId == 0) revert("FOREST: Could not find headquarter to allocate new YieldTree");

        distributeYieldTreeCompoundPayment();
        uint256 newYieldTreeId = LibYieldTree._mintYieldTree(LibProtocolMetaData._msgSender(), targetHeadquarterId);
        emit YieldTreeCompound(LibProtocolMetaData._msgSender(), newYieldTreeId);
    }
} 