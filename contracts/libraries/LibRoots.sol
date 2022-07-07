// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/******************************************************************************\
*
* @author Forest Financial Team
* @title Library for Roots
*
/******************************************************************************/

import "../libraries/LibProtocolMetaData.sol";
import "../libraries/LibTokenData.sol";
import "../libraries/LibYieldTree.sol";

library LibRoots {
    struct DiamondStorage {
        uint256 growthFactorCap;
        uint256 maxDiscount;
        uint256 tokensSoldDuringPeriod;
        uint256 tokenSupplyBeforePeriod;
        uint8 resetPeriodAfter;
        uint32 periodStart;
    }

    function _giveRootsBasedOnForest(address _for, uint256 _forestAmount) internal {
        LibProtocolMetaData.DiamondStorage storage PMds = LibProtocolMetaData.diamondStorage();
        LibRoots.DiamondStorage storage RTds = LibRoots.diamondStorage();

        _checkPeriodData();

        PMds.forestToken.transferFrom(PMds.rewardPool, address(this), _forestAmount);

        uint256 rootsBuyPrice = _getRootsBuyPrice();

        PMds.forestToken.approve(address(PMds.joeRouter), _forestAmount);

        uint256[] memory toStableSwap = PMds.joeRouter.swapExactTokensForTokens(
            _forestAmount,
            0,
            LibTokenData._getForestToStablePath(),
            address(this),
            block.timestamp
        );

        uint256 stableReceived = toStableSwap[1];
        uint256 swapTax = 10 * (10 ** (PMds.stableToken.decimals() - 2)); // 0.10%
        uint256 taxedAmount = (stableReceived * swapTax) / (1 * 10 ** (PMds.stableToken.decimals() + 2));
        uint256 rootsToReceive = (((stableReceived - taxedAmount) * (1 * 10 ** PMds.rootsToken.decimals() - PMds.stableToken.decimals())) * 10 ** PMds.rootsToken.decimals()) / rootsBuyPrice;

        PMds.stableToken.transfer(PMds.rootsTreasury, stableReceived - taxedAmount);
        PMds.stableToken.transfer(PMds.treasury, taxedAmount);

        PMds.rootsToken.mint(_for, rootsToReceive);
        RTds.tokensSoldDuringPeriod += rootsToReceive;
    }

    function _giveForestBasedOnRoots(address _for, uint256 _rootsAmount) internal {
        LibProtocolMetaData.DiamondStorage storage PMds = LibProtocolMetaData.diamondStorage();

        uint256 rootsSellingValue = (_rootsAmount * _getRootsSellPrice()) / (1 * 10 ** PMds.stableToken.decimals());
        uint256 swapTax = 10 * (10 ** (PMds.stableToken.decimals() - 2)); // 0.10%
        uint256 taxedAmount = (rootsSellingValue * swapTax) / (1 * 10 ** (PMds.stableToken.decimals() + 2));

        PMds.rootsToken.burnFrom(_for, _rootsAmount);
        PMds.stableToken.transferFrom(PMds.rootsTreasury, address(this), rootsSellingValue - taxedAmount);
        PMds.stableToken.transferFrom(PMds.rootsTreasury, PMds.treasury, taxedAmount);

        PMds.stableToken.approve(address(PMds.joeRouter), rootsSellingValue - taxedAmount);

        PMds.joeRouter.swapExactTokensForTokens(
            rootsSellingValue - taxedAmount,
            0,
            LibTokenData._getStableToForestPath(),
            _for,
            block.timestamp
        );
    }

    function _checkPeriodData() internal {
        LibRoots.DiamondStorage storage RTds = LibRoots.diamondStorage();

        if (RTds.periodStart == 0) {
            RTds.periodStart = uint32(block.timestamp);
            RTds.tokenSupplyBeforePeriod = _getRootsTotalSupply();
            RTds.tokensSoldDuringPeriod = 0;
        }

        if (uint32(block.timestamp) > RTds.periodStart + (uint32(RTds.resetPeriodAfter) * 1 days)) {
            RTds.periodStart = uint32(block.timestamp);
            RTds.tokenSupplyBeforePeriod = _getRootsTotalSupply();
            RTds.tokensSoldDuringPeriod = 0;
        }
    }

    function _getBackingPrice() internal view returns (uint256) {
        LibProtocolMetaData.DiamondStorage storage PMds = LibProtocolMetaData.diamondStorage();

        require(_getRootsTotalSupply() > 0, "FOREST: Roots supply must be atleast 1");
        return (_getRootsTreasuryBalance() * 10 ** (36 - PMds.stableToken.decimals())) / _getRootsTotalSupply();
    }

    function _getRootsTreasuryBalance() internal view returns (uint256) {
        LibProtocolMetaData.DiamondStorage storage PMds = LibProtocolMetaData.diamondStorage();
        return PMds.stableToken.balanceOf(PMds.rootsTreasury);
    }

    function _getRootsTotalSupply() internal view returns (uint256) {
        LibProtocolMetaData.DiamondStorage storage PMds = LibProtocolMetaData.diamondStorage();
        return PMds.rootsToken.totalSupply();
    }

    function _getRootsBuyPrice() internal view returns (uint256) {
        LibProtocolMetaData.DiamondStorage storage PMds = LibProtocolMetaData.diamondStorage();

        uint256 baseBackingPrice = _getBackingPrice();
        uint256 buySellMultiplier = _getBuySellMultiplier(true);

        uint256 price = (baseBackingPrice * buySellMultiplier) / (1 * 10 ** (PMds.rootsToken.decimals() + 1));
        
        return price;
    }

    function _getRootsSellPrice() internal view returns (uint256) {
        LibProtocolMetaData.DiamondStorage storage PMds = LibProtocolMetaData.diamondStorage();

        uint256 baseBackingPrice = _getBackingPrice();
        uint256 buySellMultiplier = _getBuySellMultiplier(false);

        uint256 price = (baseBackingPrice * buySellMultiplier) / (1 * 10 ** (PMds.rootsToken.decimals() + 1));
        
        return price;
    }

    function _getBuySellMultiplier(bool _isBuying) internal view returns (uint256) {
        LibProtocolMetaData.DiamondStorage storage PMds = LibProtocolMetaData.diamondStorage();

        uint256 buySellMultiplier;

        if (_isBuying) {
            buySellMultiplier = 12 * (10 ** PMds.rootsToken.decimals());
            buySellMultiplier += _getGrowthFactor();
        } else {
            buySellMultiplier = 9 * (10 ** PMds.rootsToken.decimals());
            buySellMultiplier -= _getGrowthFactor();
        }

        return buySellMultiplier;
    }

    function _getGrowthFactor() internal view returns (uint256) {
        LibProtocolMetaData.DiamondStorage storage PMds = LibProtocolMetaData.diamondStorage();
        LibRoots.DiamondStorage storage RTds = LibRoots.diamondStorage();

        uint256 growthFactor = 2 * ((RTds.tokensSoldDuringPeriod * (1 * 10 ** PMds.rootsToken.decimals())) / RTds.tokenSupplyBeforePeriod);
        
        if (growthFactor > RTds.growthFactorCap) growthFactor = RTds.growthFactorCap;

        return growthFactor;
    }

    // Returns the struct from a specified position in contract storage
    // ds is short for DiamondStorage
    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        // Specifies a random position in contract storage
        bytes32 storagePosition = keccak256("diamond.storage.LibRoots");
        // Set the position of our struct in contract storage
        assembly {
            ds.slot := storagePosition
        }
    }
}