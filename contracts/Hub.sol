// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "./HubRegistry.sol";

contract Hub is AccessControlEnumerable {
    mapping(uint256 => bool) public inputsAllowed; // set other hubs to allow input

    uint256[] internal _hubInputs;
    uint256[] internal _hubOutputs;

    // or set it allow all inputs;
    bool public allowAllInputs;
    HubRegistry public REGISTRY;

    constructor(address hubRegistryAddress, address hubAdmin) {
        REGISTRY = HubRegistry(hubRegistryAddress);
        _register();
        _setupRole(DEFAULT_ADMIN_ROLE, hubAdmin);
    }

    function hubInputs(uint256 hubID)
        public
        view
        returns (uint256[] memory inputs)
    {
        inputs = _hubInputs;
    }

    function hubOutputs(uint256 hubID)
        public
        view
        returns (uint256[] memory outputs)
    {
        outputs = _hubOutputs;
    }

    // Hub to Hub communication
    function addInput() external {
        // get hub ID of sender
        uint256 senderHubID = REGISTRY.idFromAddress(_msgSender());
        require(
            allowAllInputs || inputsAllowed[senderHubID],
            "setting input not allowed from sender"
        );
        _hubInputs.push(senderHubID);
    }

    function removeInput() external {
        // get hub ID of sender
        uint256 senderHubID = REGISTRY.idFromAddress(_msgSender());
        require(
            allowAllInputs || inputsAllowed[senderHubID],
            "removing input not allowed from sender"
        );
        //TODO: remove input
    }

    // Admin

    function setAllowAllInputs(bool allowAll)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        allowAllInputs = allowAll;
    }

    function setInputAllowed(uint256 hubID, bool allowed)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        inputsAllowed[hubID] = allowed;
    }

    function addHubConnections(uint256[] memory outputs)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        // connections = [[from hub id, to hub id]]
        require(_connectionHubsValid(outputs), "not all hub indeces valid");
        for (uint256 i = 0; i < outputs.length; i++) {
            // Set self as input on other hub
            Hub hub = Hub(REGISTRY.hubAddress(outputs[i]));
            hub.addInput();
            // Set outputs from this hub
            _hubOutputs.push(outputs[i]);
        }
    }

    function removeZoneConnectionsTo(uint256[] memory connectedHubIDs)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        /* 
        Can only remove output connections originating from self
        Inputs must be removed from the outputting hub
        */

        for (uint256 i = 0; i < connectedHubIDs.length; i++) {
            Hub hub = Hub(REGISTRY.hubAddress(connectedHubIDs[i]));
            hub.removeInput();
            //TODO:
            // remove output from self - connectedHubIDs[i]
        }
    }

    // Internal
    function _register() internal {
        require(REGISTRY.hubCanRegister(address(this)), "can't register");
        REGISTRY.register();
    }

    function _connectionHubsValid(uint256[] memory outputs)
        internal
        view
        returns (bool isValid)
    {
        // checks that all IDs passed exist
        isValid = true;
        for (uint256 i = 0; i < outputs.length; i++) {
            if (REGISTRY.hubAddress(outputs[i]) == address(0)) {
                isValid = false;
                break;
            }
        }
    }

    function _isAllowedInput(uint256 hubID)
        internal
        view
        returns (bool inputAllowed)
    {
        Hub hubToCheck = Hub(REGISTRY.hubAddress(hubID));
        inputAllowed = (hubToCheck.allowAllInputs() ||
            hubToCheck.inputsAllowed(_hubID()))
            ? true
            : false;
    }

    function _hubID() internal view returns (uint256) {
        return REGISTRY.idFromAddress(address(this));
    }
}
