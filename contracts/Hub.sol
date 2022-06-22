// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "./HubRegistry.sol";

contract Hub is AccessControlEnumerable {
    mapping(uint256 => bool) public inputAllowed; // set other hubs to allow input
    mapping(uint256 => bool) public inputActive;
    uint256[] internal _hubInputs;
    uint256[] internal _hubOutputs;

    // or set it allow all inputs;
    bool public allowAllInputs;
    HubRegistry public REGISTRY;

    modifier onlyAuthorizedHub() {
        require(
            allowAllInputs ||
                inputAllowed[REGISTRY.idFromAddress(_msgSender())],
            "hub not authorized"
        );
        _;
    }

    constructor(address hubRegistryAddress, address hubAdmin) {
        REGISTRY = HubRegistry(hubRegistryAddress);
        _register();
        _setupRole(DEFAULT_ADMIN_ROLE, hubAdmin);
    }

    function hubInputs() public view returns (uint256[] memory inputs) {
        inputs = _hubInputs;
    }

    function hubOutputs() public view returns (uint256[] memory outputs) {
        outputs = _hubOutputs;
    }

    // Hub to Hub communication
    function addInput() external onlyAuthorizedHub {
        // get hub ID of sender
        uint256 hubID = REGISTRY.idFromAddress(_msgSender());
        _hubInputs.push(hubID);
        inputActive[hubID] = true;
    }

    function enterUser(address userAddress) external virtual onlyAuthorizedHub {
        require(
            inputActive[REGISTRY.idFromAddress(_msgSender())],
            "origin hub not set as input"
        );
        _userWillEnter(userAddress);
        _userDidEnter(userAddress);
    }

    function removeInput() external onlyAuthorizedHub {
        uint256 hubID = REGISTRY.idFromAddress(_msgSender());
        _hubInputs.push(hubID);
        //TODO: remove input
        inputActive[hubID] = false;
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
        inputAllowed[hubID] = allowed;
    }

    function addHubConnections(uint256[] memory outputs)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_connectionHubsValid(outputs), "not all hub indeces valid");
        for (uint256 i = 0; i < outputs.length; i++) {
            // Set self as input on other hub
            Hub hub = Hub(REGISTRY.hubAddress(outputs[i]));
            hub.addInput();
            // Set outputs from this hub
            _hubOutputs.push(outputs[i]);
        }
    }

    function removeHubConnectionsTo(uint256[] memory connectedHubIDs)
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

    // Custom Behaviors
    function _userWillEnter(address userAddress) internal virtual {}

    function _userDidEnter(address userAddress) internal virtual {}

    function _userWillExit(address userAddress) internal virtual {}

    function _userDidExit(address userAddress) internal virtual {}

    function _railcarWillEnter(uint256 railcarID) internal virtual {}

    function _railcarDidEnter(uint256 railcarID) internal virtual {}

    function _railcarWillExit(uint256 railcarID) internal virtual {}

    function _railcarDidExit(uint256 railcarID) internal virtual {}

    // Internal

    function _sendUserToHub(address userAddress, uint256 hubID) internal {
        _userWillExit(userAddress);
        Hub(REGISTRY.hubAddress(hubID)).enterUser(userAddress);
        _userDidExit(userAddress);
    }

    function _sendUserToHub(address userAddress, string memory hubName)
        internal
    {
        _userWillExit(userAddress);
        Hub(REGISTRY.addressFromName(hubName)).enterUser(userAddress);
        _userDidExit(userAddress);
    }

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

    function _isAllowedInput(uint256 hubID) internal view returns (bool) {
        Hub hubToCheck = Hub(REGISTRY.hubAddress(hubID));
        bool allowed = (hubToCheck.allowAllInputs() ||
            hubToCheck.inputAllowed(_hubID()))
            ? true
            : false;
        return allowed;
    }

    function _hubID() internal view returns (uint256) {
        return REGISTRY.idFromAddress(address(this));
    }
}
