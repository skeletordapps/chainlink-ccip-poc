// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.27;

interface IPoints {
    function walletsPoints(address wallet) external view returns (uint256 points);
}
