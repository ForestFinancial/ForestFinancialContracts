// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/******************************************************************************\
*
* @author Forest Financial Team
* @title Facet for protocol ownership
*
/******************************************************************************/

import "../../libraries/LibDiamond.sol";
import "../../libraries/LibProtocolMeta.sol";
import "../../libraries/LibYieldTree.sol";
import "../../libraries/LibHeadquarter.sol";

contract ManagerOwnerFacet {
    modifier onlyOwner() {
        require(LibProtocolMeta.msgSender() == LibDiamond.contractOwner());
        _;
    }

    modifier hasSpaceForYieldTree(address _of) {
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();
        LibHeadquarter.DiamondStorage storage HQds = LibHeadquarter.diamondStorage();

        require(YTds.yieldtreesOf[_of].length < LibHeadquarter._getMaxYieldTreeCapacityOf(_of)
        ,
        "FOREST: No more space for a YieldTree");
        _;
    }

    function giftYieldTree(address _to) external onlyOwner hasSpaceForYieldTree(_to) {
        LibHeadquarter.DiamondStorage storage HQds = LibHeadquarter.diamondStorage();

        uint256[] memory ownedHeadquarters = HQds.headquartersOf[LibProtocolMeta.msgSender()];

        for(uint i = 0; i < ownedHeadquarters.length; i++){
            uint256 maxSpace = HQds.headquarters[ownedHeadquarters[i]].level * HQds.headquartersMetadata.maxYieldTreesPerLevel;
            uint256 remainingSpace = maxSpace - HQds.headquarters[ownedHeadquarters[i]].yieldtrees.length;

            if (remainingSpace > 0) {
                LibYieldTree._mintYieldTree(_to,  ownedHeadquarters[i]);
                break;
            }
        }
    }
}