// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {Test, console} from "forge-std/Test.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {IRouterClient, IERC20} from "@chainlink/local/CCIPLocalSimulator.sol";
import {CCIPLocalSimulatorFork, Register} from "@chainlink/local/CCIPLocalSimulatorFork.sol";
import {Ask} from "../src/Ask.sol";
import {Answer} from "../src/Answer.sol";
import {Points} from "../src/Points.sol";
import {Tiers} from "../src/Tiers.sol";
import {ITiers} from "../src/interfaces/ITiers.sol";

contract AskAndAnswerTierTest is Test {
    CCIPLocalSimulatorFork public ccipLocalSimulatorFork;
    uint256 public sourceFork;
    uint256 public destinationFork;
    IRouterClient sourceRouter;
    IRouterClient destinationRouter;
    IERC20 sourceLinkToken;
    IERC20 destinationLinkToken;

    Ask public ask;
    Answer public answer;

    uint64 public sourceChainSelector;
    uint64 public destinationChainSelector;

    address bob;
    address mary;
    address john;

    function grantInitialPoints(Points points) public {
        points.grantPoints(bob, 20_000 ether);
        points.grantPoints(mary, 150_000 ether);
        points.grantPoints(john, 201_000 ether);
    }

    function addInitialTiers(Tiers tiers) public {
        ITiers.Tier memory Jeet = ITiers.Tier("Jeet", 15_000 ether, 29_999 ether);
        ITiers.Tier memory Average = ITiers.Tier("Average", 30_000 ether, 59_999 ether);
        ITiers.Tier memory Cool = ITiers.Tier("Cool", 60_000 ether, 99_999 ether);
        ITiers.Tier memory BigCheese = ITiers.Tier("BigCheese", 100_000 ether, 199_999 ether);
        ITiers.Tier memory Chad = ITiers.Tier("Chad", 200_000 ether, 999_999_999 ether);

        tiers.addTier(Jeet.name, Jeet.min, Jeet.max);
        tiers.addTier(Average.name, Average.min, Average.max);
        tiers.addTier(Cool.name, Cool.min, Cool.max);
        tiers.addTier(BigCheese.name, BigCheese.min, BigCheese.max);
        tiers.addTier(Chad.name, Chad.min, Chad.max);
    }

    function setUp() public {
        bob = vm.addr(1);
        vm.label(bob, "bob");

        mary = vm.addr(2);
        vm.label(mary, "mary");

        john = vm.addr(3);
        vm.label(john, "john");

        string memory SOURCE_RPC_URL = vm.envString("OPTIMISM_SEPOLIA_RPC_URL");
        string memory DESTINATION_RPC_URL = vm.envString("BASE_SEPOLIA_RPC_URL");

        sourceFork = vm.createFork(SOURCE_RPC_URL);
        destinationFork = vm.createSelectFork(DESTINATION_RPC_URL);

        ccipLocalSimulatorFork = new CCIPLocalSimulatorFork();
        vm.makePersistent(address(ccipLocalSimulatorFork));

        Register.NetworkDetails memory destinationNetworkDetails =
            ccipLocalSimulatorFork.getNetworkDetails(block.chainid);

        destinationRouter = IRouterClient(destinationNetworkDetails.routerAddress);
        destinationChainSelector = destinationNetworkDetails.chainSelector;
        destinationLinkToken = IERC20(destinationNetworkDetails.linkAddress);

        Points points = new Points();
        grantInitialPoints(points);

        Tiers tiers = new Tiers(address(points));
        addInitialTiers(tiers);

        answer = new Answer(address(destinationRouter), address(tiers), address(destinationLinkToken));
        vm.makePersistent(address(answer));

        vm.selectFork(sourceFork);
        Register.NetworkDetails memory sourceNetworkDetails = ccipLocalSimulatorFork.getNetworkDetails(block.chainid);
        sourceRouter = IRouterClient(sourceNetworkDetails.routerAddress);
        sourceChainSelector = sourceNetworkDetails.chainSelector;
        sourceLinkToken = IERC20(sourceNetworkDetails.linkAddress);
        ask = new Ask(address(sourceRouter), address(sourceLinkToken));
        vm.makePersistent(address(ask));
    }

    function test_bob_CanCheckTierCrossChain() external {
        uint256 previewedFeesForAsking = ask.previewFees(destinationChainSelector, address(answer), bob);
        deal(address(sourceLinkToken), address(ask), previewedFeesForAsking);
        bytes32 messageId = ask.askTier(destinationChainSelector, address(answer), bob);

        vm.selectFork(destinationFork);
        uint256 previewedFeesForAnswering = answer.previewFees(sourceChainSelector, address(ask), bob, "Jeet");
        deal(address(destinationLinkToken), address(answer), previewedFeesForAnswering);
        ccipLocalSimulatorFork.switchChainAndRouteMessage(destinationFork);
        (bytes32 latestMessageId, address latestMessage, string memory lastAnswer) =
            answer.getLastReceivedMessageDetails();

        vm.selectFork(sourceFork);
        ccipLocalSimulatorFork.switchChainAndRouteMessage(sourceFork);

        assertEq(latestMessageId, messageId);
        assertEq(latestMessage, bob);
        assertEq(ask.tiers(bob), lastAnswer);
        assertEq(lastAnswer, "Jeet");
    }

    function test_mary_CanCheckTierCrossChain() external {
        uint256 previewedFeesForAsking = ask.previewFees(destinationChainSelector, address(answer), bob);
        deal(address(sourceLinkToken), address(ask), previewedFeesForAsking);
        bytes32 messageId = ask.askTier(destinationChainSelector, address(answer), mary);

        vm.selectFork(destinationFork);
        uint256 previewedFeesForAnswering = answer.previewFees(sourceChainSelector, address(ask), bob, "BigCheese");
        deal(address(destinationLinkToken), address(answer), previewedFeesForAnswering);
        ccipLocalSimulatorFork.switchChainAndRouteMessage(destinationFork);
        (bytes32 latestMessageId, address latestMessage, string memory lastAnswer) =
            answer.getLastReceivedMessageDetails();

        vm.selectFork(sourceFork);
        ccipLocalSimulatorFork.switchChainAndRouteMessage(sourceFork);

        assertEq(latestMessageId, messageId);
        assertEq(latestMessage, mary);
        assertEq(ask.tiers(mary), lastAnswer);
        assertEq(lastAnswer, "BigCheese");
    }

    function test_john_CanCheckTierCrossChain() external {
        uint256 previewedFeesForAsking = ask.previewFees(destinationChainSelector, address(answer), bob);
        deal(address(sourceLinkToken), address(ask), previewedFeesForAsking);
        bytes32 messageId = ask.askTier(destinationChainSelector, address(answer), john);

        vm.selectFork(destinationFork);
        uint256 previewedFeesForAnswering = answer.previewFees(sourceChainSelector, address(ask), bob, "Chad");
        deal(address(destinationLinkToken), address(answer), previewedFeesForAnswering);
        ccipLocalSimulatorFork.switchChainAndRouteMessage(destinationFork);
        (bytes32 latestMessageId, address latestMessage, string memory lastAnswer) =
            answer.getLastReceivedMessageDetails();

        vm.selectFork(sourceFork);
        ccipLocalSimulatorFork.switchChainAndRouteMessage(sourceFork);

        assertEq(latestMessageId, messageId);
        assertEq(latestMessage, john);
        assertEq(ask.tiers(john), lastAnswer);
        assertEq(lastAnswer, "Chad");
    }
}
