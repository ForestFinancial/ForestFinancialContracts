// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/******************************************************************************\
*
* @author Forest Financial Team
* @title Facet for protocol ownership
*
/******************************************************************************/

import "../../libraries/LibDiamond.sol";
import "../../libraries/LibProtocolMetaData.sol";
import "../../libraries/LibYieldTree.sol";

contract YieldTreeManageFacet {
    modifier onlyOwner() {
        require(LibProtocolMetaData._msgSender() == LibDiamond.contractOwner(), "FOREST: Caller is not the owner");
        _;
    }
    
    function initYieldTrees(
        uint256 _forestPrice,
        uint8 _percentageInEther,
        uint256 _baseRewards,
        uint256 _decayAfter,
        uint256 _decayTo,
        uint256 _decayPerDay,
        uint256 _forestFeePerMonth,
        uint8 _maxFeePrepaymentMonths
    ) external onlyOwner {
        LibProtocolMetaData.DiamondStorage storage PMds = LibProtocolMetaData.diamondStorage();
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();

        YTds.yieldtreesMetadata.forestPrice = _forestPrice;
        YTds.yieldtreesMetadata.percentageInEther = _percentageInEther;
        YTds.yieldtreesMetadata.baseRewards = _baseRewards;
        YTds.yieldtreesMetadata.decayAfter = _decayAfter;
        YTds.yieldtreesMetadata.decayTo = _decayTo;
        YTds.yieldtreesMetadata.decayPerDay = _decayPerDay;
        YTds.yieldtreesMetadata.forestFeePerMonth = _forestFeePerMonth;
        YTds.yieldtreesMetadata.maxFeePrepaymentMonths = _maxFeePrepaymentMonths;

        if (YTds.yieldtreesMetadata.forestFeePerMonth > 1 * (1 * 10 * PMds.forestToken.decimals())) YTds.yieldtreesMetadata.forestFeePerMonth = 1 * (1 * 10 * PMds.forestToken.decimals());
    }

    function setYieldTreesForestPrice(uint256 _forestPrice) external onlyOwner {
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();
        YTds.yieldtreesMetadata.forestPrice = _forestPrice;
    }

    function setYieldTreesPercentageInEther(uint8 _percentageInEther) external onlyOwner {
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();
        YTds.yieldtreesMetadata.percentageInEther = _percentageInEther;
    }

    function setYieldTreesBaseRewards(uint256 _baseRewards) external onlyOwner {
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();
        YTds.yieldtreesMetadata.baseRewards = _baseRewards;
    }

    function setYieldTreesDecayAfter(uint256 _decayAfter) external onlyOwner {
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();
        YTds.yieldtreesMetadata.decayAfter = _decayAfter;
    }

    function setYieldTreesDecayTo(uint256 _decayTo) external onlyOwner {
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();
        YTds.yieldtreesMetadata.decayTo = _decayTo;
    }

    function setYieldTreesDecayPerDay(uint8 _decayPerDay) external onlyOwner {
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();
        YTds.yieldtreesMetadata.decayPerDay = _decayPerDay;
    }

    function setYieldTreesForestFeePerMonth(uint256 _forestFeePerMonth) external onlyOwner {
        LibProtocolMetaData.DiamondStorage storage PMds = LibProtocolMetaData.diamondStorage();
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();
        YTds.yieldtreesMetadata.forestFeePerMonth = _forestFeePerMonth;
        if (YTds.yieldtreesMetadata.forestFeePerMonth > 1 * (1 * 10 * PMds.forestToken.decimals())) YTds.yieldtreesMetadata.forestFeePerMonth = 1 * (1 * 10 * PMds.forestToken.decimals());
    }

    function setYieldTreesForestFeePerMonth(uint8 _maxFeePrepaymentMonths) external onlyOwner {
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();
        YTds.yieldtreesMetadata.maxFeePrepaymentMonths = _maxFeePrepaymentMonths;
    }

    function initYieldTreesPaymentDistribution(
        uint8 _forestLiquidityPercentage,
        uint8 _forestRewardPoolPercentage,
        uint8 _forestTreasuryPercentage,
        uint8 _etherLiquidityPercentage,
        uint8 _etherRewardPoolPercentage,
        uint8 _etherTreasuryPercentage,
        uint8 _feeTreasuryPercentage,
        uint8 _feeCharityPercentage
    ) external onlyOwner {
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();

        YTds.paymentDistributionData.forestLiquidityPercentage = _forestLiquidityPercentage;
        YTds.paymentDistributionData.forestRewardPoolPercentage = _forestRewardPoolPercentage;
        YTds.paymentDistributionData.forestTreasuryPercentage = _forestTreasuryPercentage;
        YTds.paymentDistributionData.etherLiquidityPercentage = _etherLiquidityPercentage;
        YTds.paymentDistributionData.etherRewardPoolPercentage = _etherRewardPoolPercentage;
        YTds.paymentDistributionData.etherTreasuryPercentage = _etherTreasuryPercentage;
        YTds.paymentDistributionData.feeTreasuryPercentage = _feeTreasuryPercentage;
        YTds.paymentDistributionData.feeCharityPercentage = _feeCharityPercentage;
    }

    function setYieldTreesForestLiquidityPercentage(uint8 _forestLiquidityPercentage) external onlyOwner {
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();
        YTds.paymentDistributionData.forestLiquidityPercentage = _forestLiquidityPercentage;
    }

    function setYieldTreesForestRewardPoolPercentage(uint8 _forestRewardPoolPercentage) external onlyOwner {
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();
        YTds.paymentDistributionData.forestRewardPoolPercentage = _forestRewardPoolPercentage;
    }

    function setYieldTreesForestTreasuryPercentage(uint8 _forestTreasuryPercentage) external onlyOwner {
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();
        YTds.paymentDistributionData.forestTreasuryPercentage = _forestTreasuryPercentage;
    }

    function setYieldTreesEtherLiquidityPercentage(uint8 _etherLiquidityPercentage) external onlyOwner {
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();
        YTds.paymentDistributionData.etherLiquidityPercentage = _etherLiquidityPercentage;
    }

    function setYieldTreesEtherRewardPoolPercentage(uint8 _etherRewardPoolPercentage) external onlyOwner {
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();
        YTds.paymentDistributionData.etherRewardPoolPercentage = _etherRewardPoolPercentage;
    }

    function setYieldTreesEtherTreasuryPercentage(uint8 _etherTreasuryPercentage) external onlyOwner {
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();
        YTds.paymentDistributionData.etherTreasuryPercentage = _etherTreasuryPercentage;
    }

    function setYieldTreesFeeTreasuryPercentage(uint8 _feeTreasuryPercentage) external onlyOwner {
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();
        YTds.paymentDistributionData.feeTreasuryPercentage = _feeTreasuryPercentage;
    }

    function setYieldTreesFeeCharityPercentage(uint8 _feeCharityPercentage) external onlyOwner {
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();
        YTds.paymentDistributionData.feeCharityPercentage = _feeCharityPercentage;
    }     
}