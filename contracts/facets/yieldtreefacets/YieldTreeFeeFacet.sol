// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/******************************************************************************\
*
* @author Forest Financial Team
* @title Responsible for fees on the YieldTrees
*
/******************************************************************************/

import "../../interfaces/IERC721.sol";
import "../../libraries/LibProtocolMeta.sol";
import "../../libraries/LibYieldTree.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract YieldTreeFeeFacet is ReentrancyGuard {
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

    function payYieldTreeFee(uint256 _yieldtreeId)
        public
        notBlacklisted
        ownsYieldTree(_yieldtreeId)
        nonReentrant
        payable
    {
        LibProtocolMeta.DiamondStorage storage PMds = LibProtocolMeta.diamondStorage();
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();

        uint256 forestTokenPrice = LibTokenData._getForestDollarPrice();
        uint256 etherTokenPrice = LibTokenData._getEtherDollarPrice();
        uint256 forestFee = YTds.yieldtreesMetadata.forestFeePerMonth;
        uint256 forestFeeUSD = (forestTokenPrice / 1000000000000000000) * forestFee;
        uint256 requiredValue = (forestFeeUSD * 10 ** 18) / etherTokenPrice;

        require(msg.value > requiredValue, "FOREST: Insufficient value");
        payable(PMds.treasury).transfer(msg.value);

        LibYieldTree._feePaidOfYieldTree(_yieldtreeId);
    }

    function payAllYieldTreeFees()
        public
        notBlacklisted
        nonReentrant
        payable
    {
        LibProtocolMeta.DiamondStorage storage PMds = LibProtocolMeta.diamondStorage();
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();

        uint256 forestTokenPrice = LibTokenData._getForestDollarPrice();
        uint256 etherTokenPrice = LibTokenData._getEtherDollarPrice();
        uint256 forestFee = YTds.yieldtreesMetadata.forestFeePerMonth;
        uint256 forestFeeUSD = (forestTokenPrice / 1000000000000000000) * forestFee;
        uint256 requiredValuePerYieldTree = (forestFeeUSD * 10 ** 18) / etherTokenPrice;
        
        uint256[] memory ownedYieldTrees = YTds.yieldtreesOf[LibProtocolMeta.msgSender()];

        require(msg.value > requiredValuePerYieldTree * ownedYieldTrees.length, "FOREST: Insufficient value");
        payable(PMds.treasury).transfer(msg.value);

        for(uint i = 0; i < ownedYieldTrees.length; i++){
            LibYieldTree._feePaidOfYieldTree(ownedYieldTrees[i]);
        }
    }

    function getRemainingHoursUntilFeeExpiry(uint256 _yieldtreeId) public view returns (uint256) {
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();
        LibYieldTree.YieldTree memory yieldtree = YTds.yieldtrees[_yieldtreeId];
        if (yieldtree.feeExpiryTime < block.timestamp) return 0;
        return (yieldtree.feeExpiryTime - block.timestamp) / 60 / 60;
    }
}