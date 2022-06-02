// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "./HubRegistry.sol";

contract Hub is AccessControlEnumerable {
    mapping(uint256 => uint256[]) internal _hubInputs;
    mapping(uint256 => uint256[]) internal _hubOutputs;
    mapping(uint256 => bool) public inputsAllowed; // set other hubs to allow input
    // or set it allow all inputs;
    bool public allowAllInputs;
    HubRegistry internal REGISTRY;

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
        inputs = _hubInputs[hubID];
    }

    function hubOutputs(uint256 hubID)
        public
        view
        returns (uint256[] memory outputs)
    {
        outputs = _hubOutputs[hubID];
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

    function addHubConnections(uint256[2][] memory connections)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        // connections = [[from hub id, to hub id]]
        require(_connectionHubsValid(connections), "not all hub indeces valid");
        // TODO: require inputs are allowed from this hub
        for (uint256 i = 0; i < connections.length; i++) {
            _hubOutputs[connections[i][0]].push(connections[i][1]);
            _hubInputs[connections[i][1]].push(connections[i][0]);
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
            //TODO:
            // remove input from output hub - connections[i][0]
            // remove output from input hub - connections[i][1]
        }
    }

    // Internal
    function _register() internal {
        require(REGISTRY.hubCanRegister(address(this)), "can't register");
        REGISTRY.register();
    }

    function _connectionHubsValid(uint256[2][] memory connections)
        internal
        view
        returns (bool isValid)
    {
        // checks that all IDs passed exist
        for (uint256 i = 0; i < connections.length; i++) {
            isValid = true;
            if (
                REGISTRY.hubAddress(connections[i][0]) == address(0) ||
                REGISTRY.hubAddress(connections[i][1]) == address(0)
            ) {
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
