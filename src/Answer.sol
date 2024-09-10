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

contract Answer is CCIPReceiver {
    bytes32 private lastReceivedMessageId;
    address private lastReceivedWallet;
    string private lastAnswer;
    ITiers private samuraiTiers;
    IRouterClient private router;
    IERC20 private linkToken;

    constructor(address _router, address _samuraiTiers, address _link) CCIPReceiver(_router) {
        router = IRouterClient(_router);
        samuraiTiers = ITiers(_samuraiTiers);
        linkToken = IERC20(_link);
    }

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

    function getLastReceivedMessageDetails()
        external
        view
        returns (bytes32 messageId, address wallet, string memory answer)
    {
        return (lastReceivedMessageId, lastReceivedWallet, lastAnswer);
    }

    function previewFees(uint64 destinationChainSelector, address receiver, address wallet, string memory tierName)
        public
        view
        returns (uint256)
    {
        Client.EVM2AnyMessage memory evm2AnyMessage = mountMessage(receiver, wallet, tierName);
        return router.getFee(destinationChainSelector, evm2AnyMessage);
    }

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
