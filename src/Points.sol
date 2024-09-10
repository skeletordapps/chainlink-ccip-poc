// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

contract Points {
    mapping(address wallet => uint256 walletPoints) public walletsPoints;

    function grantPoints(address wallet, uint256 points) external {
        walletsPoints[wallet] = points;
    }
}
