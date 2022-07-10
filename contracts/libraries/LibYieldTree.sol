// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/******************************************************************************\
*
* @author Forest Financial Team
* @title Library for a YieldTree
*
/******************************************************************************/

import "../interfaces/IERC721.sol";
import "../libraries/LibProtocolMetaData.sol";
import "../libraries/LibTokenData.sol";
import "../libraries/LibHeadquarter.sol";
import "../libraries/LibCoreNFT.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

library LibYieldTree {
    using Counters for Counters.Counter;
    
    struct YieldTree {
        address owner; // Address of the YieldTree owner
        uint256 headquarterId; // Id of the headquarter the YieldTree is assigned to

        uint32 creationTime; // Timestamp of creation
        uint32 lastClaimTime; // Timestamp of last claim
        uint32 lastFeePaidTime; // Last time wage of forester was paid
        uint32 feeExpiryTime; // Timestamp after which fee expires

        uint256 totalClaimed; // Total claimed tokens
        uint256 foresterId; // The assigned forester

        uint8 coreNFTType; // Attached coreNFT type
        uint256 coreNFTId; // Attached coreNFT id
    }

    struct Metadata {
        uint256 forestPrice; // The full price of a single YieldTree.
        uint8 percentageInEther; // The percentage of tokenPrice which has to be paid in ether, this amount will be subracted from tokenPrice. If set to 0, no ether has to be paid and YieldTree has to be paid fully in forestToken
        
        uint256 baseRewards; // Starting daily reward amount
        uint256 decayAfter; // Amount of days after which decay starts
        uint256 decayTo; // Amount to decay to after decayAfterRewardedForest has been reached
        uint256 decayPerDay; // Amount to decay each day until it reaches decayTo

        uint256 forestFeePerMonth; // Monthly fee in forest per month.
        uint8 maxFeePrepaymentMonths; // Amount of months someone can prepay the yieldtrees their fees
    }

    struct PaymentDistribution {
        uint8 forestLiquidityPercentage;
        uint8 forestRewardPoolPercentage;
        uint8 forestTreasuryPercentage;
        uint8 etherLiquidityPercentage;
        uint8 etherRewardPoolPercentage;
        uint8 etherTreasuryPercentage;
        uint8 feeTreasuryPercentage;
        uint8 feeCharityPercentage;
    }

    struct RewardSnapshotter {
        uint32 snapshotTime;
        uint256 snapshottedRewards;
    }

    struct DiamondStorage {
        mapping(uint256 => YieldTree) yieldtrees; // YieldTreeID => YieldTreeStruct
        mapping(address => uint256[]) yieldtreesOf; // Mapping containing array of owned YieldTrees
        mapping(uint256 => RewardSnapshotter) rewardSnapshots;
        Metadata yieldtreesMetadata; // General metadata for the YieldTrees
        PaymentDistribution paymentDistributionData;
        Counters.Counter yieldtreeCounterId; // Responsible for giving YieldTrees a special id
    }

    function _feePaidOfYieldTree(uint256 _yieldtreeId) internal {
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();
        YieldTree storage targetYieldtree = YTds.yieldtrees[_yieldtreeId];

        targetYieldtree.lastFeePaidTime = uint32(block.timestamp);

        uint32 newExpiryDate = uint32(targetYieldtree.feeExpiryTime + 30 days);
        uint256 exceedingDays = ((block.timestamp + (YTds.yieldtreesMetadata.maxFeePrepaymentMonths * 30 days)) - targetYieldtree.feeExpiryTime) / 60 / 60 / 24;

        if (exceedingDays > 0) newExpiryDate = uint32(newExpiryDate - (exceedingDays * 1 days));

        targetYieldtree.feeExpiryTime = newExpiryDate;
    }

    function _mintYieldTree(address _for, uint256 _headquarterId) internal returns (uint256) {
        LibProtocolMetaData.DiamondStorage storage PMds = LibProtocolMetaData.diamondStorage();
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();
        LibHeadquarter.DiamondStorage storage HQds = LibHeadquarter.diamondStorage();
        LibHeadquarter.Headquarter storage headquarter = HQds.headquarters[_headquarterId];

        YTds.yieldtreeCounterId.increment();
        uint256 id = YTds.yieldtreeCounterId.current();

        YieldTree memory newYieldTree;
        newYieldTree.owner = _for;
        newYieldTree.headquarterId = _headquarterId;
        newYieldTree.creationTime = uint32(block.timestamp);
        newYieldTree.lastFeePaidTime = uint32(block.timestamp);
        newYieldTree.feeExpiryTime = uint32(block.timestamp + (30 * 1 days));

        YTds.yieldtreesOf[_for].push(id);
        YTds.yieldtrees[id] = newYieldTree;
        headquarter.yieldtrees.push(id);

        RewardSnapshotter memory newRewardSnapshotter;
        newRewardSnapshotter.snapshotTime = uint32(block.timestamp);
        YTds.rewardSnapshots[id] = newRewardSnapshotter;

        PMds.totalYieldTrees += 1;

        return id;
    }

    function _takeRewardsSnapshot(uint256 _yieldtreeId) internal {
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();

        YTds.rewardSnapshots[_yieldtreeId].snapshottedRewards = _getRewardsOf(_yieldtreeId);
        YTds.rewardSnapshots[_yieldtreeId].snapshotTime = uint32(block.timestamp);
    }

    function _resetRewardsSnapshot(uint256 _yieldtreeId) internal {
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();

        YTds.rewardSnapshots[_yieldtreeId].snapshottedRewards = 0;
        YTds.rewardSnapshots[_yieldtreeId].snapshotTime = uint32(block.timestamp);
    }

    function _getRewardsOf(uint256 _yieldtreeId) internal view returns(uint256) {
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();

        uint256 lastSnapshotTime = YTds.rewardSnapshots[_yieldtreeId].snapshotTime;
        uint256 lastSnapshottedRewards = YTds.rewardSnapshots[_yieldtreeId].snapshottedRewards;

        uint256 rewardsToAdd;

        // HAS TO CHANGE TO DAYS AGAIN "/ 24", now on hours for testing purposes
        uint256 daysPassedSinceSnapshot = (block.timestamp - lastSnapshotTime) / 60 / 60;

        for (uint i = 1; i < daysPassedSinceSnapshot + 1; i++) {
            rewardsToAdd += _getRewardsOnDaysAfterSnapshot(_yieldtreeId, i);
        }

        return lastSnapshottedRewards + rewardsToAdd;
    }

    function _getRewardsOnDaysAfterSnapshot(uint256 _yieldtreeId, uint256 _daysAfterSnapshot) internal view returns(uint256) {
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();

        YieldTree memory yieldtree = YTds.yieldtrees[_yieldtreeId];

        uint256 lastSnapshotTime = YTds.rewardSnapshots[_yieldtreeId].snapshotTime;
        uint256 daysPassedSinceMint = ((lastSnapshotTime + (_daysAfterSnapshot * 1 days)) - yieldtree.creationTime) / 60 / 60 / 24;

        uint256 toReward;

        if (daysPassedSinceMint > YTds.yieldtreesMetadata.decayAfter) {
            // decay started
            uint256 totalDecayAmount = (daysPassedSinceMint - YTds.yieldtreesMetadata.decayAfter) * YTds.yieldtreesMetadata.decayPerDay;

            if (totalDecayAmount > (YTds.yieldtreesMetadata.baseRewards - YTds.yieldtreesMetadata.decayTo)) {
                toReward += YTds.yieldtreesMetadata.decayTo;
            } else {
                toReward += (YTds.yieldtreesMetadata.baseRewards - totalDecayAmount);
            }
        } else {
            toReward += YTds.yieldtreesMetadata.baseRewards;
        }

        if (yieldtree.coreNFTType != 0 && yieldtree.coreNFTId != 0) {
            LibCoreNFT.CoreNFT memory coreNFT = LibCoreNFT._getCoreNFT(yieldtree.coreNFTId, yieldtree.coreNFTType);
            IERC721 coreNFTContract = LibCoreNFT._getCoreNFTContract(yieldtree.coreNFTType);
            uint256 coreNFTBoost = LibCoreNFT._getCoreNFTBoost(yieldtree.coreNFTType);

            if (yieldtree.owner == coreNFTContract.ownerOf(yieldtree.coreNFTId) && coreNFT.yieldtreeId == _yieldtreeId) {
                toReward += coreNFTBoost;
            }
        }

        return toReward;
    }

    function _getEtherPrice() internal view returns (uint256) {
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();

        if (YTds.yieldtreesMetadata.percentageInEther == 0) return 0;

        uint256 dollarPerToken = LibTokenData._getForestDollarPrice();
        uint256 tokenAmountToConvert = (YTds.yieldtreesMetadata.forestPrice / 100) * YTds.yieldtreesMetadata.percentageInEther;

        return (tokenAmountToConvert * dollarPerToken) / LibTokenData._getEtherDollarPrice();
    }

    function _getTokenPrice() internal view returns (uint256) {
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();

        if (YTds.yieldtreesMetadata.percentageInEther <= 0) return YTds.yieldtreesMetadata.forestPrice;

        uint8 percentageToSubstract = YTds.yieldtreesMetadata.percentageInEther;
        uint256 amountToSubstract = (YTds.yieldtreesMetadata.forestPrice / 100) * percentageToSubstract;
        
        return YTds.yieldtreesMetadata.forestPrice - amountToSubstract;
    }

    // Returns the struct from a specified position in contract storage
    // ds is short for DiamondStorage
    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        // Specifies a random position in contract storage
        bytes32 storagePosition = keccak256("diamond.storage.LibYieldTree");
        // Set the position of our struct in contract storage
        assembly {
            ds.slot := storagePosition
        }
    }
}