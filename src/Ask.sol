// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {IERC20} from
    "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import {ICrossChainMessages} from "./interfaces/ICrossChainMessages.sol";
import {console} from "forge-std/Test.sol";

contract Ask is CCIPReceiver {
    IRouterClient private router;
    IERC20 private linkToken;
    mapping(address wallet => string name) public tiers;

    constructor(address _router, address _link) CCIPReceiver(_router) {
        router = IRouterClient(_router);
        linkToken = IERC20(_link);
    }

    function previewFees(uint64 destinationChainSelector, address receiver, address wallet)
        public
        view
        returns (uint256)
    {
        Client.EVM2AnyMessage memory evm2AnyMessage = mountMessage(receiver, wallet);
        return router.getFee(destinationChainSelector, evm2AnyMessage);
    }

    function askTier(uint64 destinationChainSelector, address receiver, address wallet)
        external
        returns (bytes32 messageId)
    {
        Client.EVM2AnyMessage memory evm2AnyMessage = mountMessage(receiver, wallet);
        uint256 fees = previewFees(destinationChainSelector, receiver, wallet);

        require(
            fees <= linkToken.balanceOf(address(this)),
            ICrossChainMessages.NotEnoughBalance(linkToken.balanceOf(address(this)), fees)
        );

        linkToken.approve(address(router), fees);
        messageId = router.ccipSend(destinationChainSelector, evm2AnyMessage);
        emit ICrossChainMessages.MessageSent(
            messageId, destinationChainSelector, receiver, wallet, "", address(linkToken), fees
        );

        return messageId;
    }

    function _ccipReceive(Client.Any2EVMMessage memory any2EvmMessage) internal override {
        (address wallet, string memory tierName) = abi.decode(any2EvmMessage.data, (address, string));

        tiers[wallet] = tierName;
    }

    function mountMessage(address receiver, address wallet) private view returns (Client.EVM2AnyMessage memory) {
        Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver),
            data: abi.encode(wallet),
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: Client._argsToBytes(Client.EVMExtraArgsV1({gasLimit: 500_000})),
            feeToken: address(linkToken)
        });

        return evm2AnyMessage;
    }
}
