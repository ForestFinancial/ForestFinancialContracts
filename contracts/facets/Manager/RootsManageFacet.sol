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
import "../../libraries/LibRoots.sol";

contract RootsManageFacet {
    modifier onlyOwner() {
        require(LibProtocolMetaData._msgSender() == LibDiamond.contractOwner(), "FOREST: Caller is not the owner");
        _;
    }

    function initRoots(
        uint256 _growthFactorCap,
        uint256 _maxDiscount
    ) external onlyOwner {
        LibRoots.DiamondStorage storage RTds = LibRoots.diamondStorage();

        RTds.growthFactorCap = _growthFactorCap;
        RTds.maxDiscount = _maxDiscount;
    }

    function setRootsGrowthFactorCap(uint256 _growthFactorCap) external onlyOwner {
        LibRoots.DiamondStorage storage RTds = LibRoots.diamondStorage();
        RTds.growthFactorCap = _growthFactorCap;
    }

    function setRootsMaxDiscount(uint256 _maxDiscount) external onlyOwner {
        LibRoots.DiamondStorage storage RTds = LibRoots.diamondStorage();
        RTds.maxDiscount = _maxDiscount;        
    }
}