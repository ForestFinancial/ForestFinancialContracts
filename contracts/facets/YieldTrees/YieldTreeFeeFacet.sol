// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/******************************************************************************\
*
* @author Forest Financial Team
* @title Responsible for fees on the YieldTrees
*
/******************************************************************************/

import "../../interfaces/IERC721.sol";
import "../../libraries/LibProtocolMetaData.sol";
import "../../libraries/LibYieldTree.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract YieldTreeFeeFacet is ReentrancyGuard {
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
    * @dev Distributes the fee payment
    /******************************************************************************/
    function distributeYieldTreeFeePayment(uint256 _etherAmount) internal {
        LibProtocolMetaData.DiamondStorage storage PMds = LibProtocolMetaData.diamondStorage();
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();

        uint256 etherToTreasury = (_etherAmount / 100) * YTds.paymentDistributionData.feeTreasuryPercentage;
        uint256 etherToCharity = (_etherAmount / 100) * YTds.paymentDistributionData.feeCharityPercentage;

        payable(PMds.treasury).transfer(etherToTreasury);
        payable(PMds.charity).transfer(etherToCharity);
    }

    /******************************************************************************\
    * @dev Function for paying fees of a YieldTree
    /******************************************************************************/
    function payYieldTreeFee(uint256 _yieldtreeId)
        public
        notBlacklisted
        ownsYieldTree(_yieldtreeId)
        nonReentrant
        payable
    {
        LibProtocolMetaData.DiamondStorage storage PMds = LibProtocolMetaData.diamondStorage();
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();

        uint256 forestTokenPrice = LibTokenData._getForestDollarPrice();
        uint256 etherTokenPrice = LibTokenData._getEtherDollarPrice();

        uint256 forestFeePerMonth = YTds.yieldtreesMetadata.forestFeePerMonth;
        uint256 forestFeeUSD = (forestTokenPrice * forestFeePerMonth) / (1 * 10 ** PMds.forestToken.decimals());
        uint256 requiredValue = (forestFeeUSD * (10 ** PMds.forestToken.decimals())) / etherTokenPrice;

        require(msg.value > requiredValue, "FOREST: Insufficient value");
        
        distributeYieldTreeFeePayment(msg.value);
        LibYieldTree._feePaidOfYieldTree(_yieldtreeId);
    }

    /******************************************************************************\
    * @dev Function for paying fees for all YieldTrees belonging to caller
    /******************************************************************************/
    function payAllYieldTreeFees()
        public
        notBlacklisted
        nonReentrant
        payable
    {
        LibProtocolMetaData.DiamondStorage storage PMds = LibProtocolMetaData.diamondStorage();
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();

        uint256 forestTokenPrice = LibTokenData._getForestDollarPrice();
        uint256 etherTokenPrice = LibTokenData._getEtherDollarPrice();

        uint256 forestFeePerMonth = YTds.yieldtreesMetadata.forestFeePerMonth;
        uint256 forestFeeUSD = (forestTokenPrice * forestFeePerMonth) / (1 * 10 ** PMds.forestToken.decimals());
        uint256 requiredValuePerYieldTree = (forestFeeUSD * (10 ** PMds.forestToken.decimals())) / etherTokenPrice;
        
        uint256[] memory ownedYieldTrees = YTds.yieldtreesOf[LibProtocolMetaData._msgSender()];

        require(msg.value > (requiredValuePerYieldTree * ownedYieldTrees.length), "FOREST: Insufficient value");

        distributeYieldTreeFeePayment(msg.value);
        for(uint i = 0; i < ownedYieldTrees.length; i++) LibYieldTree._feePaidOfYieldTree(ownedYieldTrees[i]);
    }

    /******************************************************************************\
    * @dev Returns total hours until the last paid fees expire
    /******************************************************************************/
    function getRemainingHoursUntilFeeExpiry(uint256 _yieldtreeId) public view returns (uint256) {
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();
        LibYieldTree.YieldTree memory yieldtree = YTds.yieldtrees[_yieldtreeId];
        if (yieldtree.feeExpiryTime < block.timestamp) return 0;
        return (yieldtree.feeExpiryTime - block.timestamp) / 60 / 60;
    }
}