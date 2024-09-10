// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

/**
 * @title Points
 * @notice It provides a function to grant points to a specific wallet.
 * @dev This contract manages points for wallets.
 */
contract Points {
    mapping(address wallet => uint256 walletPoints) public walletsPoints;

    /**
     * @notice Grants a specified amount of points to a wallet.
     * @dev Only the contract owner can grant points.
     * @param wallet The address of the wallet to grant points to.
     * @param points The amount of points to grant.
     */
    function grantPoints(address wallet, uint256 points) external {
        walletsPoints[wallet] = points;
    }
}
