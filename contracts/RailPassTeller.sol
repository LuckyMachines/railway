// SPDX-License-Identifier:MIT
pragma solidity ^0.8.6;

import "@opengsn/paymasters/contracts/AcceptEverythingPaymaster.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

/// - if at least one sender is allowlisted, then ONLY allowlisted senders are allowed.
/// - if at least one target is allowlisted, then ONLY allowlisted targets are allowed.
contract RailPassTeller is AcceptEverythingPaymaster, AccessControlEnumerable {
    mapping(address => bool) public senderAllowlist;
    mapping(address => bool) public targetAllowlist;
    mapping(address => uint256) public allowance;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    // Public
    function addValue() public payable {
        _addAllowance(_msgSender(), msg.value);
    }

    function addValue(address user) public payable {
        _addAllowance(user, msg.value);
    }

    // External
    function preRelayedCall(
        GsnTypes.RelayRequest calldata relayRequest,
        bytes calldata signature,
        bytes calldata approvalData,
        uint256 maxPossibleGas
    )
        external
        virtual
        override
        returns (bytes memory context, bool revertOnRecipientRevert)
    {
        (signature, maxPossibleGas);
        require(approvalData.length == 0, "approvalData: invalid length");
        require(
            relayRequest.relayData.paymasterData.length == 0,
            "paymasterData: invalid length"
        );

        require(
            senderAllowlist[relayRequest.request.from],
            "sender not allowlisted"
        );

        // require(
        //     targetAllowlist[relayRequest.request.to],
        //     "target not allowlisted"
        // );
        require(
            allowance[relayRequest.request.from] >= relayRequest.request.value,
            "request exceeds allowance"
        );

        return ("", false);
    }

    function postRelayedCall(
        bytes calldata context,
        bool success,
        uint256 gasUseWithoutPost,
        GsnTypes.RelayData calldata relayData
    ) external virtual override {
        (context, success, gasUseWithoutPost, relayData);
        // subtract amount spent from allowance
    }

    // Internal
    function _allowlistSender(address sender) internal {
        senderAllowlist[sender] = true;
    }

    function _allowlistTarget(address target) internal {
        targetAllowlist[target] = true;
    }

    function _addAllowance(address user, uint256 value) internal {
        allowance[user] += value;
        _allowlistSender(user);
    }

    /*
    struct RelayData {
        uint256 gasPrice;
        uint256 pctRelayFee;
        uint256 baseRelayFee;
        address relayWorker;
        address paymaster;
        address forwarder;
        bytes paymasterData;
        uint256 clientId;
    }

    //note: must start with the ForwardRequest to be an extension of the generic forwarder
    struct RelayRequest {
        IForwarder.ForwardRequest request;
        RelayData relayData;
    }

     struct ForwardRequest {
        address from;
        address to;
        uint256 value;
        uint256 gas;
        uint256 nonce;
        bytes data;
        uint256 validUntil;
    }
    */
}
