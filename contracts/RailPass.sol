// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

import "@opengsn/contracts/src/BaseRelayRecipient.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

// import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

// OR contract RailPass is ERC2771Context
contract RailPass is BaseRelayRecipient, AccessControlEnumerable {
    // test state
    address public lastRailPassUser;

    /**
     * Set the trustedForwarder address either in constructor or
     * in other init function in your contract
     */
    // OR constructor(address _trustedForwarder) public ERC2771Context(_trustedForwarder)
    constructor(address _trustedForwarder) {
        _setTrustedForwarder(_trustedForwarder);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function setTrustedForwarder(address _forwarder)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setTrustedForwarder(_forwarder);
    }

    function useRailPass() external {
        lastRailPassUser = _msgSender();
    }

    /**
     * Override this function.
     * This version is to keep track of BaseRelayRecipient you are using
     * in your contract.
     */
    function versionRecipient() external view override returns (string memory) {
        return "2.2.6";
    }

    // internal
    function _msgSender()
        internal
        view
        virtual
        override(BaseRelayRecipient, Context)
        returns (address ret)
    {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    function _msgData()
        internal
        view
        virtual
        override(BaseRelayRecipient, Context)
        returns (bytes calldata ret)
    {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }
}
