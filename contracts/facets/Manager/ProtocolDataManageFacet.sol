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

contract YieldTreeManageFacet {
    modifier onlyOwner() {
        require(LibProtocolMetaData._msgSender() == LibDiamond.contractOwner(), "FOREST: Caller is not the owner");
        _;
    }
    
    function initProtocolMetaData(
        address _treaury,
        address _rewardPool,
        address _rootsTreasury,
        address _charity,
        address _forestToken,
        address _rootsToken,
        address _stableToken,
        address _foresterNFT,
        address _joeRouter,
        address _joeFactory,
        address _joePair,
        address _priceFeed
    ) external onlyOwner {
        LibProtocolMetaData.DiamondStorage storage PMds = LibProtocolMetaData.diamondStorage();

        PMds.treasury = _treaury;
        PMds.rewardPool = _rewardPool;
        PMds.rootsTreasury = _rootsTreasury;
        PMds.charity = _charity;
        PMds.forestToken = IERC20(_forestToken);
        PMds.rootsToken = IERC20(_rootsToken);
        PMds.stableToken = IERC20(_stableToken);
        PMds.foresterNFT = IERC721(_foresterNFT);
        PMds.joeRouter = IJoeRouter02(_joeRouter);
        PMds.joeFactory = IJoeFactory(_joeFactory);
        PMds.joePair = IJoePair(_joePair);
        PMds.priceFeed = AggregatorV3Interface(_priceFeed);
    }

    function setTreasury(address _treasury) external onlyOwner {
        LibProtocolMetaData.DiamondStorage storage PMds = LibProtocolMetaData.diamondStorage();
        PMds.treasury = _treasury;
    }

    function setRewardPool(address _rewardPool) external onlyOwner {
        LibProtocolMetaData.DiamondStorage storage PMds = LibProtocolMetaData.diamondStorage();
        PMds.rewardPool = _rewardPool;
    }

    function setRootsTreasury(address _rootsTreasury) external onlyOwner {
        LibProtocolMetaData.DiamondStorage storage PMds = LibProtocolMetaData.diamondStorage();
        PMds.rootsTreasury = _rootsTreasury;
    }

    function setCharity(address _charity) external onlyOwner {
        LibProtocolMetaData.DiamondStorage storage PMds = LibProtocolMetaData.diamondStorage();
        PMds.charity = _charity;
    }

    function setForestToken(address _forestToken) external onlyOwner {
        LibProtocolMetaData.DiamondStorage storage PMds = LibProtocolMetaData.diamondStorage();
        PMds.forestToken = IERC20(_forestToken); 
    }

    function setRootsToken(address _rootsToken) external onlyOwner {
        LibProtocolMetaData.DiamondStorage storage PMds = LibProtocolMetaData.diamondStorage();
        PMds.rootsToken = IERC20(_rootsToken);  
    }

    function setStableToken(address _stableToken) external onlyOwner {
        LibProtocolMetaData.DiamondStorage storage PMds = LibProtocolMetaData.diamondStorage();
        PMds.stableToken = IERC20(_stableToken);  
    }

    function setForesterNFT(address _foresterNFT) external onlyOwner {
        LibProtocolMetaData.DiamondStorage storage PMds = LibProtocolMetaData.diamondStorage();
        PMds.foresterNFT = IERC721(_foresterNFT);  
    }

    function setJoeRouter(address _joeRouter) external onlyOwner {
        LibProtocolMetaData.DiamondStorage storage PMds = LibProtocolMetaData.diamondStorage();
        PMds.joeRouter = IJoeRouter02(_joeRouter);  
    }

    function setJoeFactory(address _joeFactory) external onlyOwner {
        LibProtocolMetaData.DiamondStorage storage PMds = LibProtocolMetaData.diamondStorage();
        PMds.joeFactory = IJoeFactory(_joeFactory);  
    }

    function setJoePair(address _joePair) external onlyOwner {
        LibProtocolMetaData.DiamondStorage storage PMds = LibProtocolMetaData.diamondStorage();
        PMds.joePair = IJoePair(_joePair);  
    }

    function setPriceFeed(address _priceFeed) external onlyOwner {
        LibProtocolMetaData.DiamondStorage storage PMds = LibProtocolMetaData.diamondStorage();
        PMds.priceFeed = AggregatorV3Interface(_priceFeed);  
    }
}