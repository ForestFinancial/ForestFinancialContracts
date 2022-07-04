// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/******************************************************************************\
*
* @author Forest Financial Team
* @title Library for a Headquarter
*
/******************************************************************************/

import "../libraries/LibYieldTree.sol";
import "../libraries/LibProtocolMeta.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

library LibHeadquarter {
    using Counters for Counters.Counter;

    struct Headquarter {
        string continent; // Continent of the Headquarter
        address owner; // Address of the Headquarter owner
        uint256[] yieldtrees; // All the YieldTree ids under this Headquarter
        uint32 creationTime; // Timestamp of creation
        uint8 level; // Level of the Headquarter
    }

    struct Metadata {
        uint8 maxBalance;
        uint8 maxLevel;
        uint8 maxYieldTreesPerLevel;
        uint256 forestPrice; // Price = baseTokenPrice * current max YieldTree capacity (balance * maxYieldTreesPerLevel)
    }

    struct DiamondStorage {
        mapping(uint256 => Headquarter) headquarters; // HeadquarterID => Headquarter struct
        mapping(address => uint256[]) headquartersOf; // Mapping containing array of owned Headquarters
        Metadata headquartersMetadata; // General metadata for the Headquarters
        Counters.Counter headquarterCounterId; // Responsible for giving headquarters a special id
    }

    /******************************************************************************\
    * @dev Reason for having the mint function inside this library is to make this function easily callable by each facet
    /******************************************************************************/
    function _mintHeadquarter(address _for, string memory _continent) internal returns (uint256) {
        LibProtocolMeta.DiamondStorage storage PMds = LibProtocolMeta.diamondStorage();
        LibHeadquarter.DiamondStorage storage HQds = LibHeadquarter.diamondStorage();

        HQds.headquarterCounterId.increment();
        uint256 id = HQds.headquarterCounterId.current();

        LibHeadquarter.Headquarter memory newHeadquarter;
        newHeadquarter.continent = _continent;
        newHeadquarter.owner = _for;
        newHeadquarter.creationTime = uint32(block.timestamp);
        newHeadquarter.level = 1;

        HQds.headquartersOf[_for].push(id);
        HQds.headquarters[id] = newHeadquarter;

        PMds.totalHeadquarters += 1;

        return id;
    }

    function _upgradeHeadquarter(uint256 _headquarterId) internal {
        LibHeadquarter.DiamondStorage storage HQds = LibHeadquarter.diamondStorage();
        LibHeadquarter.Headquarter storage headquarter = HQds.headquarters[_headquarterId];
        headquarter.level += 1;
    }

    /******************************************************************************\
    * @dev Returns the current max amount of YieldTrees a address can have
    /******************************************************************************/
    function _getMaxYieldTreeCapacityOf(address _of) internal view returns(uint256) {
        LibHeadquarter.DiamondStorage storage ds = LibHeadquarter.diamondStorage();
        uint256[] memory ownedHeadquarters = ds.headquartersOf[_of];
        uint256 totalLevels = 0;
        for (uint256 i = 0; i < ownedHeadquarters.length; i++) totalLevels += ds.headquarters[ownedHeadquarters[i]].level;
        return totalLevels * ds.headquartersMetadata.maxYieldTreesPerLevel;
    }

    /******************************************************************************\
    * @dev Returns the price to either buy a new Headquarter or upgrade a existing one
    /******************************************************************************/
    function _calculatePrice(address _for) internal view returns (uint256) {
        LibHeadquarter.DiamondStorage storage ds = LibHeadquarter.diamondStorage();
        uint256 maxCapacity = LibHeadquarter._getMaxYieldTreeCapacityOf(_for);
        return ds.headquartersMetadata.forestPrice * maxCapacity;
    }

    // Returns the struct from a specified position in contract storage
    // ds is short for DiamondStorage
    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        // Specifies a random position in contract storage
        bytes32 storagePosition = keccak256("diamond.storage.LibHeadquarter");
        // Set the position of our struct in contract storage
        assembly {
            ds.slot := storagePosition
        }
    }
}