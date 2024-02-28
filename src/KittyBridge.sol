// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {KittyBridgeBase} from "./base/KittyBridgeBase.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {IERC20} from
    "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.0/contracts/token/ERC20/IERC20.sol";
import {KittyConnect} from "./KittyConnect.sol";

/**
 * @title KittyBridge
 * @author Shikhar Agarwal
 * @notice This contract allows users to bridge their Kitty NFT from one chain to another chain via Chainlink CCIP
 */
contract KittyBridge is KittyBridgeBase, CCIPReceiver, Ownable {

    /// @notice Constructor initializes the contract with the router address.
    /// @param _router The address of the router contract.
    /// @param _link The address of the link contract.
    /// @param kittyConnectOwner The owner of KittyConnect contract
    /// @dev This contract will be deployed by the KittyConnect contract during its creation
    constructor(address _router, address _link, address kittyConnectOwner) CCIPReceiver(_router) {
        _transferOwnership(kittyConnectOwner);
        s_linkToken = IERC20(_link);
        kittyConnect = msg.sender;
        gaslimit = 400000;
    }

    /// @dev Updates the allowlist status of a destination chain for transactions.
    function allowlistDestinationChain(uint64 _destinationChainSelector, bool allowed) external onlyOwner {
        allowlistedDestinationChains[_destinationChainSelector] = allowed;
    }

    /// @dev Updates the allowlist status of a source chain for transactions.
    function allowlistSourceChain(uint64 _sourceChainSelector, bool allowed) external onlyOwner {
        allowlistedSourceChains[_sourceChainSelector] = allowed;
    }

    /// @dev Updates the allowlist status of a sender for transactions.
    function allowlistSender(address _sender, bool allowed) external onlyOwner {
        allowlistedSenders[_sender] = allowed;
    }

    /// @notice Sends data to receiver on the destination chain.
    /// @notice Pay for fees in LINK.
    /// @param _destinationChainSelector The identifier (aka selector) for the destination blockchain.
    /// @param _receiver The address of the recipient on the destination blockchain.
    /// @param _data The payload data.
    /// @return messageId The ID of the CCIP message that was sent.
    function bridgeNftWithData(uint64 _destinationChainSelector, address _receiver, bytes memory _data)
        external
        onlyAllowlistedDestinationChain(_destinationChainSelector)
        validateReceiver(_receiver)
        returns (bytes32 messageId)
    {
        // Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
        Client.EVM2AnyMessage memory evm2AnyMessage = _buildCCIPMessage(_receiver, _data, address(s_linkToken));

        // Initialize a router client instance to interact with cross-chain router
        IRouterClient router = IRouterClient(this.getRouter());

        // Get the fee required to send the CCIP message
        uint256 fees = router.getFee(_destinationChainSelector, evm2AnyMessage);

        if (fees > s_linkToken.balanceOf(address(this))) {
            revert KittyBridge__NotEnoughBalance(s_linkToken.balanceOf(address(this)), fees);
        }

        messageId = router.ccipSend(_destinationChainSelector, evm2AnyMessage);

        emit MessageSent(messageId, _destinationChainSelector, _receiver, _data, address(s_linkToken), fees);

        return messageId;
    }

    /// handling a received message
    function _ccipReceive(Client.Any2EVMMessage memory any2EvmMessage)
        internal
        override
        onlyAllowlisted(any2EvmMessage.sourceChainSelector, msg.sender)
    {
        KittyConnect(kittyConnect).mintBridgedNFT(any2EvmMessage.data);

        emit MessageReceived(
            any2EvmMessage.messageId,
            any2EvmMessage.sourceChainSelector,
            abi.decode(any2EvmMessage.sender, (address)),
            any2EvmMessage.data
        );
    }

    /// @notice Construct a CCIP message.
    /// @param _receiver The address of the receiver.
    /// @param _data The data to be sent.
    /// @param _feeTokenAddress The address of the token used for fees. Set address(0) for native gas.
    /// @return Client.EVM2AnyMessage Returns an EVM2AnyMessage struct which contains information for sending a CCIP message.
    function _buildCCIPMessage(address _receiver, bytes memory _data, address _feeTokenAddress)
        internal
        view
        returns (Client.EVM2AnyMessage memory)
    {
        // Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
        return Client.EVM2AnyMessage({
            receiver: abi.encode(_receiver), // ABI-encoded receiver address
            data: _data, // payload data
            tokenAmounts: new Client.EVMTokenAmount[](0), // Empty array as no tokens are transferred
            extraArgs: Client._argsToBytes(Client.EVMExtraArgsV1({gasLimit: gaslimit})),
            feeToken: _feeTokenAddress
        });
    }

    function updateGaslimit(uint256 gasLimit) external onlyOwner {
        gaslimit = gasLimit;
    }

    function getKittyConnectAddr() external view returns (address) {
        return address(kittyConnect);
    }

    function getGaslimit() external view returns (uint256) {
        return gaslimit;
    }

    function getLinkToken() external view returns (address) {
        return address(s_linkToken);
    }
}
