// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {console} from "forge-std/Test.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {IERC20} from
    "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import {ICrossChainMessages} from "./interfaces/ICrossChainMessages.sol";
import {ITiers} from "./interfaces/ITiers.sol";

/**
 * @title Answer
 * @notice The contract interacts with the `ITiers` interface to retrieve tier information and then sends a response back to the
 * originating chain using Chainlink CCIP.
 * @dev This contract acts as a receiver on the Base Chain and handles incoming cross-chain messages requesting tier information
 * for a wallet address.
 */
contract Answer is CCIPReceiver {
    bytes32 private lastReceivedMessageId;
    address private lastReceivedWallet;
    string private lastAnswer;
    ITiers private samuraiTiers;
    IRouterClient private router;
    IERC20 private linkToken;

    /**
     * @dev Constructor initializes the contract with addresses for the router, tier data source, and Link token.
     * @param _router The address of the `IRouterClient` contract.
     * @param _samuraiTiers The address of the contract implementing the `ITiers` interface.
     * @param _link The address of the Link token contract.
     */
    constructor(address _router, address _samuraiTiers, address _link) CCIPReceiver(_router) {
        router = IRouterClient(_router);
        samuraiTiers = ITiers(_samuraiTiers);
        linkToken = IERC20(_link);
    }

    /**
     * @notice Callback function that handles incoming cross-chain messages and retrieves tier information.
     * @dev This function is automatically called by the `CCIPReceiver` contract when a message is received.
     *      - Stores the message ID and wallet address from the message.
     *      - Emits an `ICrossChainMessages.MessageReceived` event with details about the received message.
     *      - Fetches tier information for the received wallet address using the `ITiers` interface.
     *      - Stores the retrieved tier name.
     *      - Calls `answerTier` to send a response message containing the tier name.
     * @param any2EvmMessage The received cross-chain message containing the wallet address.
     */
    function _ccipReceive(Client.Any2EVMMessage memory any2EvmMessage) internal override {
        lastReceivedMessageId = any2EvmMessage.messageId;
        lastReceivedWallet = abi.decode(any2EvmMessage.data, (address));

        address receiver = abi.decode(any2EvmMessage.sender, (address));

        emit ICrossChainMessages.MessageReceived(
            any2EvmMessage.messageId,
            any2EvmMessage.sourceChainSelector,
            abi.decode(any2EvmMessage.sender, (address)),
            abi.decode(any2EvmMessage.data, (address)),
            ""
        );

        ITiers.Tier memory tier = samuraiTiers.getTier(lastReceivedWallet);
        lastAnswer = tier.name;

        answerTier(any2EvmMessage.sourceChainSelector, receiver, lastReceivedWallet, tier.name);
    }

    /**
     * @notice Retrieves details about the last received message.
     * @dev This function is a view function and does not modify contract state.
     * return A tuple containing the message ID, wallet address, and retrieved tier name (if any).
     */
    function getLastReceivedMessageDetails()
        external
        view
        returns (bytes32 messageId, address wallet, string memory answer)
    {
        return (lastReceivedMessageId, lastReceivedWallet, lastAnswer);
    }

    /**
     * @notice Calculates and returns the estimated fee for sending a cross-chain message containing the tier response.
     * @dev This function is a view function and does not modify contract state.
     * @param destinationChainSelector The chain selector of the destination chain.
     * @param receiver The address of the contract on the destination chain that will receive the message.
     * @param wallet The wallet address for which tier information was requested.
     * @param tierName The tier name retrieved for the wallet.
     * @return The estimated fee in tokens for sending the message.
     */
    function previewFees(uint64 destinationChainSelector, address receiver, address wallet, string memory tierName)
        public
        view
        returns (uint256)
    {
        Client.EVM2AnyMessage memory evm2AnyMessage = mountMessage(receiver, wallet, tierName);
        return router.getFee(destinationChainSelector, evm2AnyMessage);
    }

    /**
     * @notice Sends a cross-chain message containing the tier response to the original sender.
     * @dev This function performs the following actions:
     *  - Calls `previewFees` to estimate the fee.
     *  - Checks if the contract has sufficient Link tokens for the fee.
     *  - Approves the Link token for the router to spend the required amount.
     *  - Sends the cross-chain message using `ccipSend` on the `IRouterClient`.
     *  - Emits an `ICrossChainMessages.MessageSent` event with details about the message.
     * @param destinationChainSelector The chain selector of the destination chain.
     * @param receiver The address of the contract on the destination chain that will receive the message.
     * @param wallet The wallet address for which tier information was requested.
     * @param tierName The tier name retrieved for the wallet.
     * @return messageId The message ID generated by the `IRouterClient` for tracking the message.
     */
    function answerTier(uint64 destinationChainSelector, address receiver, address wallet, string memory tierName)
        public
        returns (bytes32 messageId)
    {
        Client.EVM2AnyMessage memory evm2AnyMessage = mountMessage(receiver, wallet, tierName);

        uint256 fees = previewFees(destinationChainSelector, receiver, wallet, tierName);

        require(
            fees <= linkToken.balanceOf(address(this)),
            ICrossChainMessages.NotEnoughBalance(linkToken.balanceOf(address(this)), fees)
        );

        linkToken.approve(address(router), fees);
        messageId = router.ccipSend(destinationChainSelector, evm2AnyMessage);
        emit ICrossChainMessages.MessageSent(
            messageId, destinationChainSelector, receiver, wallet, tierName, address(linkToken), fees
        );

        return messageId;
    }

    /**
     * @notice Constructs an `EVM2AnyMessage` structure for sending cross-chain messages containing the tier response.
     * @dev This function encodes the receiver address, wallet address, and tier name into the message data.
     * @param receiver The address of the contract on the destination chain that will receive the message.
     * @param wallet The wallet address for which tier information was requested.
     * @param tierName The tier name retrieved for the wallet.
     * @return evm2AnyMessage The constructed `EVM2AnyMessage` structure.
     */
    function mountMessage(address receiver, address wallet, string memory tierName)
        private
        view
        returns (Client.EVM2AnyMessage memory)
    {
        Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver),
            data: abi.encode(wallet, tierName),
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: Client._argsToBytes(Client.EVMExtraArgsV1({gasLimit: 500_000})),
            feeToken: address(linkToken)
        });

        return evm2AnyMessage;
    }
}
