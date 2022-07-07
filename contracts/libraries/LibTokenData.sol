// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/******************************************************************************\
*
* @author Forest Financial Team
* @title Library for getting token data
*
/******************************************************************************/

import "../libraries/LibProtocolMetaData.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IJoePair.sol";
import "../interfaces/IJoeFactory.sol";

library LibTokenData {
    /******************************************************************************\
    * @dev Returns path to swap from forest WAVAX
    /******************************************************************************/
    function _getForestToWAVAXPath() internal view returns(address[] memory) {
        LibProtocolMetaData.DiamondStorage storage PMds = LibProtocolMetaData.diamondStorage();

        address[] memory path = new address[](2);

        path[0] = address(PMds.forestToken);
        path[1] = address(PMds.joeRouter.WAVAX());

        return path;        
    }

    /******************************************************************************\
    * @dev Returns path to swap from forest to stable coin
    /******************************************************************************/
    function _getForestToStablePath() internal view returns (address[] memory) {
        LibProtocolMetaData.DiamondStorage storage PMds = LibProtocolMetaData.diamondStorage();

        address[] memory path = new address[](3);

        path[0] = address(PMds.forestToken);
        path[1] = address(PMds.joeRouter.WAVAX());
        path[2] = address(PMds.stableToken);

        return path;
    }

    /******************************************************************************\
    * @dev Returns path to swap from stable coin to forest
    /******************************************************************************/
    function _getStableToForestPath() internal view returns (address[] memory) {
        LibProtocolMetaData.DiamondStorage storage PMds = LibProtocolMetaData.diamondStorage();

        address[] memory path = new address[](3);

        path[0] = address(PMds.stableToken);
        path[1] = address(PMds.joeRouter.WAVAX());
        path[2] = address(PMds.forestToken);

        return path;
    }
    
    /******************************************************************************\
    * @dev Returns forest dollar price with 18 decimals
    * @notice Must always return with 18 decimals
    /******************************************************************************/
    function _getForestDollarPrice() internal view returns (uint256) {
        LibProtocolMetaData.DiamondStorage storage PMds = LibProtocolMetaData.diamondStorage();

        uint256 avaxPerToken = _getEtherNeededPerForestToken();
        uint256 avaxDollarPrice = _getEtherDollarPrice();

        return (avaxDollarPrice * avaxPerToken) / (1 * 10 ** (PMds.forestToken.decimals() * 2));
    }

    function _getEtherNeededPerForestToken() internal view returns (uint256) {
        LibProtocolMetaData.DiamondStorage storage PMds = LibProtocolMetaData.diamondStorage();

        IJoePair joePair = PMds.joePair;
        IERC20 token0 = IERC20(joePair.token0());
        (uint256 Res0, uint256 Res1,) = joePair.getReserves();
        uint256 res1 = Res1 * (10 ** token0.decimals());

        return (res1 / Res0);
    }

    /******************************************************************************\
    * @dev Returns AVAX dollar price with 18 decimals
    * @notice Adds an extra 10 decimals due to chainlink returning it with 6 decimals
    /******************************************************************************/
    function _getEtherDollarPrice() internal view returns (uint256) {
        LibProtocolMetaData.DiamondStorage storage PMds = LibProtocolMetaData.diamondStorage();

        (, int price , , ,) = PMds.priceFeed.latestRoundData();

        return uint256(price) * 10 ** 12;
    }
}