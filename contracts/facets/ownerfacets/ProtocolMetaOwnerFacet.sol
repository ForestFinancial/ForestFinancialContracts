// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/******************************************************************************\
*
* @author Forest Financial Team
* @title Facet for protocol ownership
*
/******************************************************************************/

import "../../interfaces/IERC20.sol";
import "../../interfaces/IERC721.sol";
import "../../interfaces/IJoeRouter02.sol";
import "../../interfaces/IJoePair.sol";
import "../../interfaces/AggregatorV3Interface.sol";
import "../../libraries/LibDiamond.sol";
import "../../libraries/LibProtocolMeta.sol";

contract ProtocolMetaOwnerFacet {
    modifier onlyOwner() {
        require(LibProtocolMeta.msgSender() == LibDiamond.contractOwner());
        _;
    }

    function initProtocolMeta(
        address _treaury,
        address _rewardPool,
        address _forestToken,
        address _rootsToken,
        address _stableToken,
        address _foresterNFT,
        address _joeRouter,
        address _joeFactory,
        address _joePair,
        address _priceFeed
    ) external onlyOwner {
        LibProtocolMeta.DiamondStorage storage PMds = LibProtocolMeta.diamondStorage();

        PMds.treasury = _treaury;
        PMds.rewardPool = _rewardPool;
        PMds.forestToken = IERC20(_forestToken);
        PMds.rootsToken = IERC20(_rootsToken);
        PMds.stableToken = IERC20(_stableToken);
        PMds.foresterNFT = IERC721(_foresterNFT);
        PMds.joeRouter = IJoeRouter02(_joeRouter);
        PMds.joeFactory = IJoeFactory(_joeFactory);
        PMds.joePair = IJoePair(_joePair);
        PMds.priceFeed = AggregatorV3Interface(_priceFeed);
    }

    function setTreasury(address _newTreasuryAddress) external onlyOwner {
        LibProtocolMeta.DiamondStorage storage PMds = LibProtocolMeta.diamondStorage();
        PMds.treasury = _newTreasuryAddress;
    }

    function setRewardPool(address _newRewardPool) external onlyOwner {
        LibProtocolMeta.DiamondStorage storage PMds = LibProtocolMeta.diamondStorage();
        PMds.rewardPool = _newRewardPool;
    }

    function setForestToken(address _newForestToken) external onlyOwner {
        LibProtocolMeta.DiamondStorage storage PMds = LibProtocolMeta.diamondStorage();
        PMds.forestToken = IERC20(_newForestToken); 
    }

    function setRootsToken(address _newRootsToken) external onlyOwner {
        LibProtocolMeta.DiamondStorage storage PMds = LibProtocolMeta.diamondStorage();
        PMds.rootsToken = IERC20(_newRootsToken);  
    }

    function setStableToken(address _newStableToken) external onlyOwner {
        LibProtocolMeta.DiamondStorage storage PMds = LibProtocolMeta.diamondStorage();
        PMds.stableToken = IERC20(_newStableToken);  
    }

    function setForesterNFT(address _newForesterNFT) external onlyOwner {
        LibProtocolMeta.DiamondStorage storage PMds = LibProtocolMeta.diamondStorage();
        PMds.foresterNFT = IERC721(_newForesterNFT);  
    }

    function setJoeRouter(address _newJoeRouter) external onlyOwner {
        LibProtocolMeta.DiamondStorage storage PMds = LibProtocolMeta.diamondStorage();
        PMds.joeRouter = IJoeRouter02(_newJoeRouter);  
    }

    function setJoeFactory(address _newJoeFactory) external onlyOwner {
        LibProtocolMeta.DiamondStorage storage PMds = LibProtocolMeta.diamondStorage();
        PMds.joeFactory = IJoeFactory(_newJoeFactory);  
    }

    function setJoePair(address _newJoePair) external onlyOwner {
        LibProtocolMeta.DiamondStorage storage PMds = LibProtocolMeta.diamondStorage();
        PMds.joePair = IJoePair(_newJoePair);  
    }

    function setPriceFeed(address _newPriceFeed) external onlyOwner {
        LibProtocolMeta.DiamondStorage storage PMds = LibProtocolMeta.diamondStorage();
        PMds.priceFeed = AggregatorV3Interface(_newPriceFeed);  
    }
}