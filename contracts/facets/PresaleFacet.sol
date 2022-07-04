// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/******************************************************************************\
*
* @author Forest Financial Team
* @title Facet for Presale
*
/******************************************************************************/

import "../libraries/LibProtocolMeta.sol";
import "../libraries/LibYieldTree.sol";
import "../libraries/LibHeadquarter.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface PresaleContract {
    function balanceOf(address _of) external view returns (uint256);
}

contract PresaleFacet is ReentrancyGuard {
    modifier notBlacklisted() {
        LibProtocolMeta.DiamondStorage storage ds = LibProtocolMeta.diamondStorage();

        require(ds.blacklisted[LibProtocolMeta.msgSender()] != true, "FOREST: Address is blacklisted");
        _;
    }

    mapping(address => bool) redeemers;
    PresaleContract constant presaleContract = PresaleContract(0x52717F142C06A8287a1672B3189B544cAA77147e);

    function redeemPresale(string memory _continent)
        public
        notBlacklisted
        nonReentrant
    {
        require(redeemers[LibProtocolMeta.msgSender()] != true, "FOREST: Already redeemed from presale");
        require(presaleContract.balanceOf(LibProtocolMeta.msgSender()) > 0, "FOREST: Caller didn't buy in presale");

        LibHeadquarter.DiamondStorage storage HQds = LibHeadquarter.diamondStorage();
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();

        uint256 presaleBalance = presaleContract.balanceOf(LibProtocolMeta.msgSender());

        uint256[] memory ownedHeadquarters = HQds.headquartersOf[LibProtocolMeta.msgSender()];

        if (ownedHeadquarters.length == 0) {
            uint256 newHeadquarterId = LibHeadquarter._mintHeadquarter(LibProtocolMeta.msgSender(), _continent);
            if (presaleBalance > 5) LibHeadquarter._upgradeHeadquarter(newHeadquarterId);

            for(uint i = 0; i < presaleBalance; i++){
                uint256 newYieldTreeId = LibYieldTree._mintYieldTree(LibProtocolMeta.msgSender(), newHeadquarterId);
                YTds.rewardSnapshots[newYieldTreeId].snapshottedRewards = 700000000000000000;
            }
        } else {
            uint256 yieldtreesCreated;

            for(uint a = 0; a < ownedHeadquarters.length; a++){
                LibHeadquarter.Headquarter storage headquarter = HQds.headquarters[ownedHeadquarters[a]];

                for(uint b = 0; b < presaleBalance; b++){
                    if (headquarter.yieldtrees.length != (headquarter.level * HQds.headquartersMetadata.maxYieldTreesPerLevel)) {
                        uint256 newYieldTreeId = LibYieldTree._mintYieldTree(LibProtocolMeta.msgSender(), ownedHeadquarters[a]);
                        YTds.rewardSnapshots[newYieldTreeId].snapshottedRewards = 700000000000000000;

                        yieldtreesCreated++;
                    }
                }
            }

            if (yieldtreesCreated != presaleBalance) {
                uint256 newHeadquarterId = LibHeadquarter._mintHeadquarter(LibProtocolMeta.msgSender(), _continent);
                if ((presaleBalance - yieldtreesCreated) > 5) LibHeadquarter._upgradeHeadquarter(newHeadquarterId);

                for(uint i = 0; i < presaleBalance - yieldtreesCreated; i++){
                    uint256 newYieldTreeId = LibYieldTree._mintYieldTree(LibProtocolMeta.msgSender(), newHeadquarterId);
                    YTds.rewardSnapshots[newYieldTreeId].snapshottedRewards = 700000000000000000;
                }
            }
        }

        redeemers[LibProtocolMeta.msgSender()] = true;
    }

    function hasRedeemedPresale(address _of) public view returns (bool) {
        return redeemers[LibProtocolMeta.msgSender()];
    }
} 