// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/******************************************************************************\
*
* @author Forest Financial Team
* @title Facet for protocol ownership
*
/******************************************************************************/

import "../../libraries/LibDiamond.sol";
import "../../libraries/LibYieldTree.sol";
import "../../libraries/LibProtocolMeta.sol";

contract YieldTreeOwnerFacet {
    modifier onlyOwner() {
        require(LibProtocolMeta.msgSender() == LibDiamond.contractOwner());
        _;
    }

    function initYieldTrees(
        uint256 _forestPrice,
        uint256 _forestFeePerMonth,
        uint8 _maxFeePrepaymentMonths,
        uint8 _percentageInEther,
        uint256 _baseRewards,
        uint256 _decayAfter,
        uint256 _decayTo,
        uint256 _decayPerDay
    ) external onlyOwner {
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();

        YTds.yieldtreesMetadata.forestPrice = _forestPrice;
        YTds.yieldtreesMetadata.forestFeePerMonth = _forestFeePerMonth;
        YTds.yieldtreesMetadata.maxFeePrepaymentMonths = _maxFeePrepaymentMonths;
        YTds.yieldtreesMetadata.percentageInEther = _percentageInEther;
        YTds.yieldtreesMetadata.baseRewards = _baseRewards;
        YTds.yieldtreesMetadata.decayAfter = _decayAfter;
        YTds.yieldtreesMetadata.decayTo = _decayTo;
        YTds.yieldtreesMetadata.decayPerDay = _decayPerDay;
    }

    function initYieldTreesPaymentData(
        uint8 _forestLiquidityPercentage,
        uint8 _forestRewardPoolPercentage,
        uint8 _forestTreasuryPercentage,
        uint8 _etherLiquidityPercentage,
        uint8 _etherRewardPercentage,
        uint8 _etherTreasuryPercentage
    ) external onlyOwner {
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();

        YTds.paymentDistributionData.forestLiquidityPercentage = _forestLiquidityPercentage;
        YTds.paymentDistributionData.forestRewardPoolPercentage = _forestRewardPoolPercentage;
        YTds.paymentDistributionData.forestTreasuryPercentage = _forestTreasuryPercentage;
        YTds.paymentDistributionData.etherLiquidityPercentage = _etherLiquidityPercentage;
        YTds.paymentDistributionData.etherRewardPercentage = _etherRewardPercentage;
        YTds.paymentDistributionData.etherTreasuryPercentage = _etherTreasuryPercentage;
    }

    function setYieldTreesForestPrice(uint256 _newForestPrice) external onlyOwner {
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();
        YTds.yieldtreesMetadata.forestPrice = _newForestPrice;
    }

    function setYieldTreesPercentageInEther(uint8 _newPercentageInEther) external onlyOwner {
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();
        YTds.yieldtreesMetadata.percentageInEther = _newPercentageInEther;
    }

    function setYieldTreesBaseRewards(uint256 _newBaseRewards) external onlyOwner {
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();
        YTds.yieldtreesMetadata.baseRewards = _newBaseRewards;
    }

    function setYieldTreesDecayAfter(uint256 _newDecayAfter) external onlyOwner {
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();
        YTds.yieldtreesMetadata.decayAfter = _newDecayAfter;
    }

    function setYieldTreesDecayTo(uint256 _newDecayTo) external onlyOwner {
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();
        YTds.yieldtreesMetadata.decayTo = _newDecayTo;
    }

    function setYieldTreesDecayPerDay(uint8 _newDecayPerDay) external onlyOwner {
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();
        YTds.yieldtreesMetadata.decayPerDay = _newDecayPerDay;
    }

    function setYieldTreesForestLiquidityPercentage(uint8 _newForestLiquidityPercentage) external onlyOwner {
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();
        YTds.paymentDistributionData.forestLiquidityPercentage = _newForestLiquidityPercentage;
    }

    function setYieldTreesForestRewardPoolPercentage(uint8 _newForestRewardPoolPercentage) external onlyOwner {
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();
        YTds.paymentDistributionData.forestRewardPoolPercentage = _newForestRewardPoolPercentage;
    }

    function setYieldTreesForestTreasuryPercentage(uint8 _newForestTreasuryPercentage) external onlyOwner {
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();
        YTds.paymentDistributionData.forestTreasuryPercentage = _newForestTreasuryPercentage;
    }

    function setYieldTreesEtherLiquidityPercentage(uint8 _newEtherLiquidityPercentage) external onlyOwner {
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();
        YTds.paymentDistributionData.etherLiquidityPercentage = _newEtherLiquidityPercentage;
    }

    function setYieldTreesEtherRewardPercentage(uint8 _newEtherRewardPercentage) external onlyOwner {
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();
        YTds.paymentDistributionData.etherRewardPercentage = _newEtherRewardPercentage;
    }

    function setYieldTreesEtherTreasuryPercentage(uint8 _newEtherTreasuryPercentage) external onlyOwner {
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();
        YTds.paymentDistributionData.etherTreasuryPercentage = _newEtherTreasuryPercentage;
    }
}