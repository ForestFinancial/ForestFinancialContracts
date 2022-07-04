// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/******************************************************************************\
*
* @author Forest Financial Team
* @title Library to manage liquidity
*
/******************************************************************************/

import "../libraries/LibProtocolMeta.sol";
import "../libraries/LibTokenData.sol";

library LibLiquidityManager {
    function _addLiquidity(uint256 _etherAmount, uint256 _forestAmount) internal {
        LibProtocolMeta.DiamondStorage storage PMds = LibProtocolMeta.diamondStorage();

        PMds.joeRouter.addLiquidityAVAX{ value: _etherAmount }(
            address(PMds.forestToken),
            _forestAmount,
            0,
            0,
            address(this),
            block.timestamp
        );
    }


}