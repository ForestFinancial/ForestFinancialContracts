// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/******************************************************************************\
*
* @author Forest Financial Team
* @title Library for the protocol it's meta data
*
/******************************************************************************/

import "../interfaces/IERC20.sol";
import "../interfaces/IERC721.sol";
import "../interfaces/IJoeRouter02.sol";
import "../interfaces/IJoeFactory.sol";
import "../interfaces/IJoePair.sol";
import "../interfaces/AggregatorV3Interface.sol";

library LibProtocolMetaData {
    struct DiamondStorage {
        address treasury;
        address rewardPool;
        address rootsTreasury;
        address charity;

        IERC20 forestToken;
        IERC20 rootsToken;
        IERC20 stableToken;
        IERC721 seedNFT;
        IERC721 saplingNFT;
        IERC721 treeNFT;
        IERC721 peltonNFT;

        IJoeRouter02 joeRouter;
        IJoeFactory joeFactory;
        IJoePair joePair;
        
        AggregatorV3Interface priceFeed;

        uint256 totalYieldTrees;
        uint256 totalHeadquarters;

        mapping(address => bool) admins;
        mapping(address => bool) blacklisted;
    }

    function _msgSender() internal view returns (address sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = msg.sender;
        }
    }

    // Returns the struct from a specified position in contract storage
    // ds is short for DiamondStorage
    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        // Specifies a random position in contract storage
        bytes32 storagePosition = keccak256("diamond.storage.LibProtocolMetaData");
        // Set the position of our struct in contract storage
        assembly {
            ds.slot := storagePosition
        }
    }
}