// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.27;

interface ICrossChainMessages {
    // Custom errors to provide more descriptive revert messages.
    error NotEnoughBalance(uint256 currentBalance, uint256 calculatedFees); // Used to make sure contract has enough balance.

    enum PayFeesIn {
        Native,
        LINK
    }

    struct Answer {
        address wallet;
        string tierName;
    }

    event MessageSent(
        bytes32 indexed messageId,
        uint64 indexed destinationChainSelector,
        address receiver,
        address wallet,
        string answer,
        address feeToken,
        uint256 fees
    );

    event MessageReceived(
        bytes32 indexed messageId, uint64 indexed sourceChainSelector, address sender, address wallet, string answer
    );
}
