// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/******************************************************************************\
*
* @author Forest Financial Team
* @title Facet for protocol ownership
*
/******************************************************************************/

import "../../libraries/LibDiamond.sol";
import "../../libraries/LibRoots.sol";
import "../../libraries/LibProtocolMeta.sol";

contract RootsOwnerFacet {
    modifier onlyOwner() {
        require(LibProtocolMeta.msgSender() == LibDiamond.contractOwner());
        _;
    }

    function initRoots(
        address _rootsTreasury,
        uint16 _additionalGrowthFactorCap,
        uint8 _resetPeriodAfter,
        uint256 _maxDiscount
    ) external onlyOwner {
        LibRoots.DiamondStorage storage RTds = LibRoots.diamondStorage();

        RTds.rootsTreasury = _rootsTreasury;
        RTds.additionalGrowthFactorCap = _additionalGrowthFactorCap;
        RTds.resetPeriodAfter = _resetPeriodAfter;
        RTds.maxDiscount = _maxDiscount;

        LibRoots._checkGrowthFactorData();
    }

    function setRootsTreasury(address _newRootsTreasury) external onlyOwner {
        LibRoots.DiamondStorage storage RTds = LibRoots.diamondStorage();
        RTds.rootsTreasury = _newRootsTreasury;
    }

    function setRootsAdditionalGrowthFactorCap(uint16 _newAdditionalGrowthFactorCap) external onlyOwner {
        LibRoots.DiamondStorage storage RTds = LibRoots.diamondStorage();
        RTds.additionalGrowthFactorCap = _newAdditionalGrowthFactorCap;
    }

    function setRootsResetPeriodAfter(uint8 _newResetPeriodAfter) external onlyOwner {
        LibRoots.DiamondStorage storage RTds = LibRoots.diamondStorage();
        RTds.resetPeriodAfter = _newResetPeriodAfter;
    }

    function setRootsMaxDiscount(uint256 _newMaxDiscount) external onlyOwner {
        LibRoots.DiamondStorage storage RTds = LibRoots.diamondStorage();
        RTds.maxDiscount = _newMaxDiscount;
    }

    function recoverRootsSupply() external onlyOwner {
        LibProtocolMeta.DiamondStorage storage PMds = LibProtocolMeta.diamondStorage();
        LibRoots.DiamondStorage storage RTds = LibRoots.diamondStorage();

        if (PMds.rootsToken.totalSupply() == 0) {
            PMds.rootsToken.mint(RTds.rootsTreasury, 1);
        }
    }
}