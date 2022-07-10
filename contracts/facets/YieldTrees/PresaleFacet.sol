// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/******************************************************************************\
*
* @author Forest Financial Team
* @title Facet for Presale
*
/******************************************************************************/

import "../../libraries/LibProtocolMetaData.sol";
import "../../libraries/LibYieldTree.sol";
import "../../libraries/LibHeadquarter.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface PresaleContract {
    function balanceOf(address _of) external view returns (uint256);
}

contract PresaleFacet is ReentrancyGuard {
    event PresaleClaimed(address indexed _for);

    modifier notBlacklisted() {
        LibProtocolMetaData.DiamondStorage storage PMds = LibProtocolMetaData.diamondStorage();

        require(PMds.blacklisted[LibProtocolMetaData._msgSender()] != true, "FOREST: Address is blacklisted");
        _;
    }

    mapping(address => bool) redeemers;
    PresaleContract constant presaleContract = PresaleContract(0x52717F142C06A8287a1672B3189B544cAA77147e);

    /******************************************************************************\
    * @dev Public function for redeeming the caller his Presale items
    /******************************************************************************/
    function redeemPresale(string memory _continent)
        public
        notBlacklisted
        nonReentrant
    {
        require(redeemers[LibProtocolMetaData._msgSender()] != true, "FOREST: Already redeemed from presale");
        require(presaleContract.balanceOf(LibProtocolMetaData._msgSender()) > 0, "FOREST: Caller didn't buy in presale");

        LibHeadquarter.DiamondStorage storage HQds = LibHeadquarter.diamondStorage();
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();

        uint256 presaleBalance = presaleContract.balanceOf(LibProtocolMetaData._msgSender());

        uint256[] memory ownedHeadquarters = HQds.headquartersOf[LibProtocolMetaData._msgSender()];

        if (ownedHeadquarters.length == 0) {
            uint256 newHeadquarterId = LibHeadquarter._mintHeadquarter(LibProtocolMetaData._msgSender(), _continent);
            if (presaleBalance > 5) LibHeadquarter._upgradeHeadquarter(newHeadquarterId);

            for(uint i = 0; i < presaleBalance; i++){
                uint256 newYieldTreeId = LibYieldTree._mintYieldTree(LibProtocolMetaData._msgSender(), newHeadquarterId);
                YTds.rewardSnapshots[newYieldTreeId].snapshottedRewards = 1000000000000000000;
            }
        } else {
            uint256 yieldtreesCreated;

            for(uint a = 0; a < ownedHeadquarters.length; a++){
                LibHeadquarter.Headquarter storage headquarter = HQds.headquarters[ownedHeadquarters[a]];

                for(uint b = 0; b < presaleBalance; b++){
                    if (headquarter.yieldtrees.length != (headquarter.level * HQds.headquartersMetadata.maxYieldTreesPerLevel)) {
                        uint256 newYieldTreeId = LibYieldTree._mintYieldTree(LibProtocolMetaData._msgSender(), ownedHeadquarters[a]);
                        YTds.rewardSnapshots[newYieldTreeId].snapshottedRewards = 1000000000000000000;

                        yieldtreesCreated++;
                    }
                }
            }

            if (yieldtreesCreated != presaleBalance) {
                uint256 newHeadquarterId = LibHeadquarter._mintHeadquarter(LibProtocolMetaData._msgSender(), _continent);
                if ((presaleBalance - yieldtreesCreated) > 5) LibHeadquarter._upgradeHeadquarter(newHeadquarterId);

                for(uint i = 0; i < presaleBalance - yieldtreesCreated; i++){
                    uint256 newYieldTreeId = LibYieldTree._mintYieldTree(LibProtocolMetaData._msgSender(), newHeadquarterId);
                    YTds.rewardSnapshots[newYieldTreeId].snapshottedRewards = 1000000000000000000;
                }
            }
        }

        redeemers[LibProtocolMetaData._msgSender()] = true;

        emit PresaleClaimed(LibProtocolMetaData._msgSender());
    }

    /******************************************************************************\
    * @dev Returns whether an address has already claimed his Presale items
    /******************************************************************************/
    function hasRedeemedPresale(address _of) public view returns (bool) {
        return redeemers[_of];
    }
} 