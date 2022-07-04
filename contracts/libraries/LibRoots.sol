// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/******************************************************************************\
*
* @author Forest Financial Team
* @title Library for Roots
*
/******************************************************************************/

import "../libraries/LibProtocolMeta.sol";
import "../libraries/LibTokenData.sol";
import "../libraries/LibYieldTree.sol";

library LibRoots {
    struct DiamondStorage {
        address rootsTreasury;
        uint16 additionalGrowthFactorCap;
        uint256 maxDiscount;
        uint256 tokensSoldDuringPeriod;
        uint256 tokenSupplyBeforePeriod;
        uint8 resetPeriodAfter;
        uint32 periodStart;
    }

    function _giveRootsBasedOnForest(address _for, uint256 _forestAmount) internal {
        LibProtocolMeta.DiamondStorage storage PMds = LibProtocolMeta.diamondStorage();
        LibRoots.DiamondStorage storage RTds = LibRoots.diamondStorage();

        _checkGrowthFactorData();

        PMds.forestToken.transferFrom(PMds.rewardPool, address(this), _forestAmount);

        uint256 rootsBuyPrice = _getRootsBuyPrice(_for);

        uint256[] memory toStableSwap = PMds.joeRouter.swapExactTokensForTokens(
            _forestAmount,
            0,
            LibTokenData._getForestToStablePath(),
            address(this),
            0
        );

        uint256 stableReceived = toStableSwap[1];
        uint256 internalSwapTax;
        if (stableReceived > 1000) internalSwapTax = (stableReceived / 1000);
        uint256 rootsToReceive = (rootsBuyPrice * 10 ** 7) / (stableReceived - internalSwapTax);
        PMds.stableToken.transfer(RTds.rootsTreasury, stableReceived - internalSwapTax);
        if (internalSwapTax > 0) PMds.stableToken.transfer(PMds.treasury, internalSwapTax);

        PMds.rootsToken.mint(_for, rootsToReceive);
        RTds.tokensSoldDuringPeriod += rootsToReceive;
    }

    function _giveForestBasedOnRoots(address _for, uint256 _rootsAmount) internal {
        LibProtocolMeta.DiamondStorage storage PMds = LibProtocolMeta.diamondStorage();
        LibRoots.DiamondStorage storage RTds = LibRoots.diamondStorage();

        uint256 rootsToSell = _getRootsSellPrice(_for) * _rootsAmount;
        uint256 internalSwapTax;
        if (rootsToSell > 1000) internalSwapTax = (rootsToSell / 1000);

        PMds.rootsToken.burnFrom(_for, _rootsAmount);
        PMds.stableToken.transferFrom(RTds.rootsTreasury, address(this), rootsToSell - internalSwapTax);
        if (internalSwapTax > 0) PMds.stableToken.transferFrom(RTds.rootsTreasury, PMds.treasury, internalSwapTax);

        PMds.joeRouter.swapExactTokensForTokens(
            rootsToSell - internalSwapTax,
            0,
            LibTokenData._getStableToForestPath(),
            _for,
            0
        );
    }

    function _checkGrowthFactorData() internal {
        LibRoots.DiamondStorage storage RTds = LibRoots.diamondStorage();

        if (RTds.periodStart == 0) {
            RTds.periodStart = uint32(block.timestamp);
            RTds.tokenSupplyBeforePeriod = _getRootsSupply();
            RTds.tokensSoldDuringPeriod = 0;
        }

        if (uint32(block.timestamp) > RTds.periodStart + uint32(RTds.resetPeriodAfter) * 1 days) {
            RTds.periodStart = uint32(block.timestamp);
            RTds.tokenSupplyBeforePeriod = _getRootsSupply();
            RTds.tokensSoldDuringPeriod = 0;
        }
    }

    /******************************************************************************\
    * @dev Returns the current backing price of roots
    * @notice Backing price = treasury stable balance / supply of roots
    /******************************************************************************/
    function _getBackingPrice() internal view returns (uint256) {
        require(_getRootsSupply() > 0, "FOREST: Roots supply must be atleast 1");
        return _getRootsTreasuryBalance() * 10 ** 30 / _getRootsSupply(); // Treasury balance to 36 decimals
    }

    /******************************************************************************\
    * @dev Returns stable coin balance of the roots treasury
    /******************************************************************************/
    function _getRootsTreasuryBalance() internal view returns (uint256) {
        LibProtocolMeta.DiamondStorage storage PMds = LibProtocolMeta.diamondStorage();
        LibRoots.DiamondStorage storage RTds = LibRoots.diamondStorage();

       return PMds.stableToken.balanceOf(RTds.rootsTreasury);
    }

    /******************************************************************************\
    * @dev Returns the total supply of the roots token
    /******************************************************************************/
    function _getRootsSupply() internal view returns (uint256) {
        LibProtocolMeta.DiamondStorage storage PMds = LibProtocolMeta.diamondStorage();

        return PMds.rootsToken.totalSupply();
    }

    /******************************************************************************\
    * @dev Returns the discount of a address. Returns 4 decimals.
    /******************************************************************************/
    function _getRootsDiscount(address _for) internal view returns (uint256) {
        LibRoots.DiamondStorage storage RTds = LibRoots.diamondStorage();
        LibYieldTree.DiamondStorage storage YTds = LibYieldTree.diamondStorage();
        
        uint256 discount;

        uint256 yieldtreeAmount = YTds.yieldtreesOf[_for].length;
        discount += yieldtreeAmount * 500;

        if (discount > RTds.maxDiscount) discount = RTds.maxDiscount;

        return discount;
    }

    /******************************************************************************\
    * @dev Returns the current buy price of roots using the backing price.
    /******************************************************************************/
    function _getRootsBuyPrice(address _for) internal view returns (uint256) {
        uint256 baseBackingPrice = _getBackingPrice();
        uint256 growthFactor = _getCurrentGrowthFactor(true);
        uint256 price = (baseBackingPrice / 1000) * growthFactor;
        uint256 discount = _getRootsDiscount(_for);

        if (discount > 0) {
            uint256 discountAmount = (price / 10000) * discount;
            price = price - discountAmount;
        }
        
        return price;
    }

    /******************************************************************************\
    * @dev Returns the current sell price of roots using the backing price.
    /******************************************************************************/
    function _getRootsSellPrice(address _for) internal view returns (uint256) {
        uint256 baseBackingPrice = _getBackingPrice();
        uint256 growthFactor = _getCurrentGrowthFactor(false);
        uint256 price = (baseBackingPrice / 1000) * growthFactor;
        uint256 discount = _getRootsDiscount(_for);

        if (discount > 0) {
            uint256 discountAmount = (price / 10000) * discount;
            price = price + discountAmount;
        }
        
        return price;
    }

    /******************************************************************************\
    * @dev Returns the growth factor
    * @notice 3 of the numbers returned here must represent decimals behind the .
    * Example: returned value: 567 growth factor: 0.567
    * Example: returned value: 1156 grwoth factor: 1.156
    /******************************************************************************/
    function _getCurrentGrowthFactor(bool _isBuying) internal view returns (uint256) {
        LibRoots.DiamondStorage storage RTds = LibRoots.diamondStorage();

        uint256 growthFactor;

        uint256 additionalGrowth = (200 * RTds.tokensSoldDuringPeriod) / RTds.tokenSupplyBeforePeriod;
        if (additionalGrowth > uint256(RTds.additionalGrowthFactorCap)) additionalGrowth = uint256(RTds.additionalGrowthFactorCap);

        if (_isBuying) {
            growthFactor = 1200;
            growthFactor += additionalGrowth;
        } else {
            growthFactor = 900;
            growthFactor -= additionalGrowth;
        }

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