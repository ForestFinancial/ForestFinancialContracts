// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/******************************************************************************\
*
* @author Forest Financial Team
* @title Facet for YieldTrees
*
/******************************************************************************/

import "../../interfaces/IERC721.sol";
import "../../libraries/LibProtocolMeta.sol";
import "../../libraries/LibYieldTree.sol";
import "../../libraries/LibHeadquarter.sol";
import "../../libraries/LibTokenData.sol";
import "../../libraries/LibLiquidityManager.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract YieldTreeFacet is ReentrancyGuard {
    modifier notBlacklisted() {
        LibProtocolMeta.DiamondStorage storage ds = LibProtocolMeta.diamondStorage();
        require(ds.blacklisted[LibProtocolMeta.msgSender()] != true, "FOREST: Address is blacklisted");
        _;
    }

    modifier ownsHeadquarter(uint256 _headquarterId) {
        LibHeadquarter.DiamondStorage storage ds = LibHeadquarter.diamondStorage();
        require(LibProtocolMeta.msgSender() == ds.headquarters[_headquarterId].owner, "FOREST: Caller is not owner of headquarter");
        _;
    }

    modifier ownsYieldTree(uint256 _yieldtreeId) {
        LibYieldTree.DiamondStorage storage ds = LibYieldTree.diamondStorage();
        require(LibProtocolMeta.msgSender() == ds.yieldtrees[_yieldtreeId].owner, "FOREST: Caller is not owner of YieldTree");
        _;
    }

    function distributeYieldTreePayment(uint256 _forestAmount, uint256 _etherAmount) internal {
        LibProtocolMeta.DiamondStorage storage PMds = LibProtocolMeta.diamondStorage();
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();
        LibYieldTree.PaymentDistribution memory paymentDistribution = YTds.paymentDistributionData;

        uint256 forestAmount = _forestAmount;
        uint256 etherAmount = _etherAmount;

        uint256 forestToLiquidity = (forestAmount / 100) * paymentDistribution.forestLiquidityPercentage;
        uint256 forestToRewardPool = (forestAmount / 100) * paymentDistribution.forestRewardPoolPercentage;
        uint256 forestToTreasury = (forestAmount / 100) * paymentDistribution.forestTreasuryPercentage;

        uint256 etherToLiquidity;
        uint256 etherToRewardPool;
        uint256 etherToTreasury;

        // First check if there was ether involved in the payment, as etherpercentage may be set on 0;
        if (etherAmount > 100) {
            etherToLiquidity = (etherAmount / 100) * paymentDistribution.etherLiquidityPercentage;
            etherToRewardPool = (etherAmount / 100) * paymentDistribution.etherRewardPercentage;
            etherToTreasury = (etherAmount / 100) * paymentDistribution.etherTreasuryPercentage;
        }

        PMds.forestToken.transfer(PMds.treasury, forestToTreasury);
        PMds.forestToken.transfer(PMds.rewardPool, forestToRewardPool);

        if (etherToLiquidity != 0) payable(PMds.treasury).transfer(etherToTreasury);
        if (etherToRewardPool != 0) payable(PMds.rewardPool).transfer(etherToRewardPool);

        LibLiquidityManager._addLiquidity(etherToLiquidity, forestToLiquidity);
    }

    function mintYieldTree(uint256 _headquarterId) 
        public
        notBlacklisted
        ownsHeadquarter(_headquarterId)
        nonReentrant
        payable
        returns (uint256)
    {
        LibProtocolMeta.DiamondStorage storage PMds = LibProtocolMeta.diamondStorage();
        LibHeadquarter.DiamondStorage storage HQds = LibHeadquarter.diamondStorage();

        LibHeadquarter.Headquarter memory headquarter = HQds.headquarters[_headquarterId];

        uint8 level = headquarter.level;
        uint8 maxYieldTreesPerLevel = HQds.headquartersMetadata.maxYieldTreesPerLevel;

        require(headquarter.yieldtrees.length < (level * maxYieldTreesPerLevel), "FOREST: Headquarters is on max capacity");

        uint256 forestTokenPrice = LibYieldTree._getTokenPrice();
        uint256 etherPrice = LibYieldTree._getEtherPrice();

        require(PMds.forestToken.balanceOf(LibProtocolMeta.msgSender()) > forestTokenPrice, "FOREST: Insufficient forest balance");
        require(msg.value >= etherPrice, "FOREST: Insufficient value sent");
        require(PMds.forestToken.allowance(LibProtocolMeta.msgSender(), address(this)) > forestTokenPrice, "FOREST: Insufficient allowance");

        PMds.forestToken.transferFrom(
            LibProtocolMeta.msgSender(),
            address(this),
            forestTokenPrice
        );

        distributeYieldTreePayment(forestTokenPrice, msg.value);
        return LibYieldTree._mintYieldTree(LibProtocolMeta.msgSender(),  _headquarterId);
    }

    function getTotalYieldTrees() public view returns (uint256) {
        LibProtocolMeta.DiamondStorage storage PMds = LibProtocolMeta.diamondStorage();
        return PMds.totalYieldTrees;
    }

    function getYieldTreeForestPrice() public view returns (uint256) {
        return LibYieldTree._getTokenPrice();
    }

    function getYieldTreeEtherPrice() public view returns (uint256) {
        return LibYieldTree._getEtherPrice();
    }
 
    function getYieldTreeBalance(address _of) public view returns(uint256) {
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();
        uint256[] memory yieldtrees = YTds.yieldtreesOf[_of];
        return yieldtrees.length;
    }

    function getYieldTreesOf(address _of) public view returns(uint256[] memory) {
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();
        uint256[] memory yieldtrees = YTds.yieldtreesOf[_of];
        return yieldtrees;
    }

    function getYieldTree(uint256 _id) public view returns(LibYieldTree.YieldTree memory) {
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();
        LibYieldTree.YieldTree memory yieldtree = YTds.yieldtrees[_id];
        return yieldtree;
    }
} 