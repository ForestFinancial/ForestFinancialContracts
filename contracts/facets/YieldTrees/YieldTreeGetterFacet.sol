// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/******************************************************************************\
*
* @author Forest Financial Team
* @title Responsible public getters for the front-end
*
/******************************************************************************/

import "../../libraries/LibProtocolMetaData.sol";
import "../../libraries/LibYieldTree.sol";
import "../../libraries/LibHeadquarter.sol";
import "../../libraries/LibRoots.sol";

contract YieldTreeGetterFacet {
    /******************************************************************************\
    * @dev Returns the total amount of YieldTrees in existence
    /******************************************************************************/
    function getTotalYieldTrees() public view returns (uint256) {
        LibProtocolMetaData.DiamondStorage storage PMds = LibProtocolMetaData.diamondStorage();
        return PMds.totalYieldTrees;
    }

    /******************************************************************************\
    * @dev Returns total price in Forest to buy YieldTree
    /******************************************************************************/
    function getYieldTreeFullForestPrice() public view returns (uint256) {
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();
        return YTds.yieldtreesMetadata.forestPrice;
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