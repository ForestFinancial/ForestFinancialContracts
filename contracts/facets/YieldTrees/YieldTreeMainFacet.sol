// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/******************************************************************************\
*
* @author Forest Financial Team
* @title Facet for YieldTrees
*
/******************************************************************************/

import "../../interfaces/IERC721.sol";
import "../../libraries/LibProtocolMetaData.sol";
import "../../libraries/LibYieldTree.sol";
import "../../libraries/LibHeadquarter.sol";
import "../../libraries/LibTokenData.sol";
import "../../libraries/LibLiquidityManager.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract YieldTreeMainFacet is ReentrancyGuard {
    modifier notBlacklisted() {
        LibProtocolMetaData.DiamondStorage storage PMds = LibProtocolMetaData.diamondStorage();
        require(PMds.blacklisted[LibProtocolMetaData._msgSender()] != true, "FOREST: Address is blacklisted");
        _;
    }

    modifier ownsHeadquarter(uint256 _headquarterId) {
        LibHeadquarter.DiamondStorage storage HQds = LibHeadquarter.diamondStorage();
        require(LibProtocolMetaData._msgSender() == HQds.headquarters[_headquarterId].owner, "FOREST: Caller is not owner of headquarter");
        _;
    }

    modifier ownsYieldTree(uint256 _yieldtreeId) {
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();
        require(LibProtocolMetaData._msgSender() == YTds.yieldtrees[_yieldtreeId].owner, "FOREST: Caller is not owner of YieldTree");
        _;
    }

    modifier headquarterNotOnMaxCapacity(uint256 _headquarterId) {
        LibHeadquarter.DiamondStorage storage HQds = LibHeadquarter.diamondStorage();
        LibHeadquarter.Headquarter memory headquarter = HQds.headquarters[_headquarterId];
        require(headquarter.yieldtrees.length < (headquarter.level * HQds.headquartersMetadata.maxYieldTreesPerLevel), "FOREST: Headquarter is on max capacity");
        _;
    }

    /******************************************************************************\
    * @dev Distributes the payment of a YieldTree
    /******************************************************************************/
    function distributeYieldTreePayment(uint256 _forestAmount, uint256 _etherAmount) internal {
        LibProtocolMetaData.DiamondStorage storage PMds = LibProtocolMetaData.diamondStorage();
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

    /******************************************************************************\
    * @dev Function for minting a YieldTree
    /******************************************************************************/
    function mintYieldTree(uint256 _headquarterId) 
        public
        notBlacklisted
        ownsHeadquarter(_headquarterId)
        headquarterNotOnMaxCapacity(_headquarterId)
        nonReentrant
        payable
        returns (uint256)
    {
        LibProtocolMetaData.DiamondStorage storage PMds = LibProtocolMetaData.diamondStorage();

        uint256 forestTokenPrice = LibYieldTree._getTokenPrice();
        uint256 etherPrice = LibYieldTree._getEtherPrice();

        require(PMds.forestToken.allowance(LibProtocolMetaData._msgSender(), address(this)) > forestTokenPrice, "FOREST: Insufficient allowance");
        require(PMds.forestToken.balanceOf(LibProtocolMetaData._msgSender()) > forestTokenPrice, "FOREST: Insufficient forest balance");
        require(msg.value >= etherPrice, "FOREST: Insufficient value sent");

        PMds.forestToken.transferFrom(
            LibProtocolMetaData._msgSender(),
            address(this),
            forestTokenPrice
        );

        distributeYieldTreePayment(forestTokenPrice, msg.value);
        return LibYieldTree._mintYieldTree(LibProtocolMetaData._msgSender(),  _headquarterId);
    }

    /******************************************************************************\
    * @dev Returns the total amount of YieldTrees in existence
    /******************************************************************************/
    function getTotalYieldTrees() public view returns (uint256) {
        LibProtocolMetaData.DiamondStorage storage PMds = LibProtocolMetaData.diamondStorage();
        return PMds.totalYieldTrees;
    }

    /******************************************************************************\
    * @dev Returns Forest Token price to buy a YieldTree
    /******************************************************************************/
    function getYieldTreeForestPrice() public view returns (uint256) {
        return LibYieldTree._getTokenPrice();
    }

    /******************************************************************************\
    * @dev Returns ether price to buy a YieldTree
    /******************************************************************************/
    function getYieldTreeEtherPrice() public view returns (uint256) {
        return LibYieldTree._getEtherPrice();
    }

    /******************************************************************************\
    * @dev Returns YieldTree balance of specific address
    /******************************************************************************/
    function getYieldTreeBalance(address _of) public view returns(uint256) {
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();
        uint256[] memory yieldtrees = YTds.yieldtreesOf[_of];
        return yieldtrees.length;
    }

    /******************************************************************************\
    * @dev Returns all YieldTree id's owned by specific address
    /******************************************************************************/
    function getYieldTreesOf(address _of) public view returns(uint256[] memory) {
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();
        uint256[] memory yieldtrees = YTds.yieldtreesOf[_of];
        return yieldtrees;
    }

    /******************************************************************************\
    * @dev Returns all YieldTree data of specific id
    /******************************************************************************/
    function getYieldTree(uint256 _id) public view returns(LibYieldTree.YieldTree memory) {
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();
        LibYieldTree.YieldTree memory yieldtree = YTds.yieldtrees[_id];
        return yieldtree;
    }
} 