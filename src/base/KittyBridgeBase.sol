// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {IERC20} from
    "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.0/contracts/token/ERC20/IERC20.sol";

abstract contract KittyBridgeBase {
    error KittyBridge__NotEnoughBalance(uint256 currentBalance, uint256 calculatedFees);
    error KittyBridge__NothingToWithdraw();
    error KittyBridge__FailedToWithdrawEth(address owner, address target, uint256 value);
    error KittyBridge__DestinationChainNotAllowlisted(uint64 destinationChainSelector);
    error KittyBridge__SourceChainNotAllowlisted(uint64 sourceChainSelector);
    error KittyBridge__SenderNotAllowlisted(address sender);
    error KittyBridge__InvalidReceiverAddress();
    error KittyBridge__NotKittyConnect();

    event MessageSent(
        bytes32 indexed messageId,
        uint64 indexed destinationChainSelector,
        address receiver,
        bytes data,
        address feeToken,
        uint256 fees
    );

    event MessageReceived(bytes32 indexed messageId, uint64 indexed sourceChainSelector, address sender, bytes data);

    uint256 internal gaslimit;
    mapping(uint64 => bool) public allowlistedDestinationChains;
    mapping(uint64 => bool) public allowlistedSourceChains;
    mapping(address => bool) public allowlistedSenders;
    IERC20 internal s_linkToken;
    address internal kittyConnect;

    modifier onlyAllowlistedDestinationChain(uint64 _destinationChainSelector) {
        if (!allowlistedDestinationChains[_destinationChainSelector]) {
            revert KittyBridge__DestinationChainNotAllowlisted(_destinationChainSelector);
        }
        _;
    }

    modifier onlyAllowlisted(uint64 _sourceChainSelector, address _sender) {
        if (!allowlistedSourceChains[_sourceChainSelector]) {
            revert KittyBridge__SourceChainNotAllowlisted(_sourceChainSelector);
        }
        if (!allowlistedSenders[_sender]) revert KittyBridge__SenderNotAllowlisted(_sender);
        _;
    }

    modifier validateReceiver(address _receiver) {
        if (_receiver == address(0)) revert KittyBridge__InvalidReceiverAddress();
        _;
    }

    modifier onlyKittyConnect() {
        if (msg.sender != kittyConnect) {
            revert KittyBridge__NotKittyConnect();
        }
        _;
    }
}