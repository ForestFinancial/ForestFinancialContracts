// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/******************************************************************************\
*
* @author Forest Financial Team
* @title Facet for YieldTrees
*
/******************************************************************************/

import "../../libraries/LibProtocolMetaData.sol";
import "../../libraries/LibYieldTree.sol";
import "../../libraries/LibHeadquarter.sol";
import "../../libraries/LibTokenData.sol";
import "../../libraries/LibLiquidityManager.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract YieldTreeMainFacet is ReentrancyGuard {
    event YieldTreeMinted(address indexed _for, uint256 indexed _newYieldTreeId);

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

        uint256 forestToLiquidity = (_forestAmount * (paymentDistribution.forestLiquidityPercentage * (1 * 10 ** PMds.forestToken.decimals()))) / (1 * 10 ** PMds.forestToken.decimals() + 2);
        uint256 forestToRewardPool = (_forestAmount * (paymentDistribution.forestRewardPoolPercentage * (1 * 10 ** PMds.forestToken.decimals()))) / (1 * 10 ** PMds.forestToken.decimals() + 2);
        uint256 forestToTreasury = (_forestAmount * (paymentDistribution.forestTreasuryPercentage * (1 * 10 ** PMds.forestToken.decimals()))) / (1 * 10 ** PMds.forestToken.decimals() + 2);

        uint256 etherToLiquidity = (_etherAmount * (paymentDistribution.etherLiquidityPercentage * (1 * 10 ** PMds.forestToken.decimals()))) / (1 * 10 ** PMds.forestToken.decimals() + 2);
        uint256 etherToRewardPool = (_etherAmount * (paymentDistribution.etherRewardPoolPercentage * (1 * 10 ** PMds.forestToken.decimals()))) / (1 * 10 ** PMds.forestToken.decimals() + 2);
        uint256 etherToTreasury = (_etherAmount * (paymentDistribution.etherTreasuryPercentage * (1 * 10 ** PMds.forestToken.decimals()))) / (1 * 10 ** PMds.forestToken.decimals() + 2);

        PMds.forestToken.transfer(PMds.treasury, forestToTreasury);
        PMds.forestToken.transfer(PMds.rewardPool, forestToRewardPool);

        if (etherToLiquidity != 0) payable(PMds.treasury).transfer(etherToTreasury);
        if (etherToRewardPool != 0) payable(PMds.rewardPool).transfer(etherToRewardPool);

        if (etherToLiquidity != 0 && forestToLiquidity != 0) {
            LibLiquidityManager._addLiquidity(etherToLiquidity, forestToLiquidity);
        } else {
            uint256[] memory toEtherSwap = PMds.joeRouter.swapExactTokensForTokens(
                forestToLiquidity / 2,
                0,
                LibTokenData._getForestToWAVAXPath(),
                address(this),
                block.timestamp
            );

            LibLiquidityManager._addLiquidity(toEtherSwap[1], forestToLiquidity / 2);
        }
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
        uint256 newYieldTreeId = LibYieldTree._mintYieldTree(LibProtocolMetaData._msgSender(),  _headquarterId);
        emit YieldTreeMinted(LibProtocolMetaData._msgSender(), newYieldTreeId);
        return newYieldTreeId;
    }
} 