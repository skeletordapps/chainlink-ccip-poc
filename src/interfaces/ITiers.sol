// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.27;

interface ITiers {
    struct Tier {
        string name;
        uint256 min;
        uint256 max;
    }

    function getTier(address wallet) external view returns (ITiers.Tier memory);
}
