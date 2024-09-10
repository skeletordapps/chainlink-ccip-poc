//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.27;

import {ITiers} from "./interfaces/ITiers.sol";
import {IPoints} from "./interfaces/IPoints.sol";

/**
 * @title Tiers
 * @notice It provides functions to add new tiers, retrieve a tier based on a wallet's points,
 * and get tier information by its name.
 * @dev This contract manages tiers based on wallet points.
 */
contract Tiers {
    IPoints iPoints;
    uint256 public counter;

    mapping(uint256 index => ITiers.Tier tier) public tiers;

    /**
     * @dev Constructor initializes the contract with the `Points` contract address.
     * @param _points The address of the `Points` contract.
     */
    constructor(address _points) {
        iPoints = IPoints(_points);
    }

    /**
     * @notice Adds a new tier to the contract.
     * @dev Only the contract owner can add new tiers.
     * @param name The name of the new tier.
     * @param min The minimum points required to be part of the tier.
     * @param max The maximum points allowed for the tier.
     */
    function addTier(string memory name, uint256 min, uint256 max) external {
        uint256 index = counter + 1;
        tiers[index] = ITiers.Tier(name, min, max);
        counter++;
    }

    /**
     * @notice Gets the tier a wallet belongs to based on its points.
     * @param wallet The address of the wallet to check.
     * @return The tier information for the wallet.
     */
    function getTier(address wallet) public view returns (ITiers.Tier memory) {
        // Get wallet points
        uint256 walletPoints = iPoints.walletsPoints(wallet);

        // Iterate through tiers to find a matching tier
        for (uint256 i = 1; i <= counter; i++) {
            // start from 1 because tiers mapping starts from 1
            ITiers.Tier memory tier = tiers[i];
            if ((walletPoints >= tier.min && walletPoints <= tier.max)) {
                return tier;
            }
        }

        // If no tier matches, return a blank tier
        return ITiers.Tier("", 0, 0);
    }

    /**
     * @notice Gets the tier information by its name.
     * @param name The name of the tier to get.
     * @return The tier information matching the name.
     */
    function getTierByName(string memory name) public view returns (ITiers.Tier memory) {
        bytes32 nameHash = keccak256(abi.encodePacked(name));

        for (uint256 i = 1; i <= counter; i++) {
            bytes32 tierNameHash = keccak256(abi.encodePacked(tiers[i].name));
            if (nameHash == tierNameHash) return tiers[i];
        }

        // If no tier matches, return a blank tier
        return ITiers.Tier("", 0, 0);
    }
}
