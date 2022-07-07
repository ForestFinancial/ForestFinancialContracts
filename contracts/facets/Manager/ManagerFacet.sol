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
import "../../libraries/LibHeadquarter.sol";

contract ManagerFacet {
    modifier onlyOwner() {
        require(LibProtocolMetaData._msgSender() == LibDiamond.contractOwner(), "FOREST: Caller is not the owner");
        _;
    }

    modifier onlyOwnerOrAdmin() {
        LibProtocolMetaData.DiamondStorage storage PMds = LibProtocolMetaData.diamondStorage();

        require(
            LibProtocolMetaData._msgSender() == LibDiamond.contractOwner()
            ||
            PMds.admins[LibProtocolMetaData._msgSender()] == true,
            "FOREST: Caller must either be an admin or the owner"
        );
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

    /******************************************************************************\
    * @dev Function for adding a admin address to the protocol
    /******************************************************************************/
    function addAdmin(address _admin) external onlyOwner {
        LibProtocolMetaData.DiamondStorage storage PMds = LibProtocolMetaData.diamondStorage();
        PMds.admins[_admin] = true;
    }

    /******************************************************************************\
    * @dev Function for removing a admin address to the protocol
    /******************************************************************************/
    function removeAdmin(address _admin) external onlyOwner {
        LibProtocolMetaData.DiamondStorage storage PMds = LibProtocolMetaData.diamondStorage();
        PMds.admins[_admin] = false;
    }

    /******************************************************************************\
    * @dev Function for gifting a YieldTree to give address; only if address still has space in a Headquarter
    /******************************************************************************/
    function giftYieldTree(address _to) external onlyOwnerOrAdmin hasSpaceForYieldTree(_to) {
        LibHeadquarter.DiamondStorage storage HQds = LibHeadquarter.diamondStorage();

        uint256[] memory ownedHeadquarters = HQds.headquartersOf[LibProtocolMetaData._msgSender()];

        for(uint i = 0; i < ownedHeadquarters.length; i++){
            uint256 maxSpace = HQds.headquarters[ownedHeadquarters[i]].level * HQds.headquartersMetadata.maxYieldTreesPerLevel;
            uint256 remainingSpace = maxSpace - HQds.headquarters[ownedHeadquarters[i]].yieldtrees.length;

            if (remainingSpace > 0) {
                LibYieldTree._mintYieldTree(_to, ownedHeadquarters[i]);
                break;
            }
        }
    }
}