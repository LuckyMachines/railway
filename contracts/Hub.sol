// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "./HubRegistry.sol";

contract Hub is AccessControlEnumerable {
    // mapping from hub IDs
    mapping(uint256 => bool) public inputAllowed; // set other hubs to allow input
    mapping(uint256 => bool) public inputActive;
    uint256[] internal _hubInputs;
    uint256[] internal _hubOutputs;

    // mappings from user addresses
    mapping(address => bool) public userIsInHub;

    // mappings from railcar IDs
    mapping(uint256 => bool) public groupIsInHub;

    // or set it allow all inputs;
    bool public allowAllInputs;
    HubRegistry public REGISTRY;

    event UserDidExit(address indexed user);
    event UserDidEnter(address indexed user);
    event UserTransited(
        address indexed user,
        address indexed origin,
        address indexed destination
    );
    event GroupDidExit(uint256 indexed railcarID);
    event GroupDidEnter(uint256 indexed railcarID);
    event GroupTransited(
        uint256 indexed railcarID,
        address indexed origin,
        address indexed destination
    );

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
    function addInput() public onlyAuthorizedHub {
        // get hub ID of sender
        uint256 hubID = REGISTRY.idFromAddress(_msgSender());
        _hubInputs.push(hubID);
        inputActive[hubID] = true;
    }

    function enterUser(address userAddress) public virtual onlyAuthorizedHub {
        require(
            inputActive[REGISTRY.idFromAddress(_msgSender())],
            "origin hub not set as input"
        );
        require(_userCanEnter(userAddress), "user unable to enter");
        _userWillEnter(userAddress);
        _userDidEnter(userAddress);
    }

    function enterGroup(uint256 railcarID) public virtual onlyAuthorizedHub {
        require(
            inputActive[REGISTRY.idFromAddress(_msgSender())],
            "origin hub not set as input"
        );
        require(_groupCanEnter(railcarID), "group unable to enter");
        _groupWillEnter(railcarID);
        _groupDidEnter(railcarID);
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

    function setInputsAllowed(uint256[] memory hubIDs, bool[] memory allowed)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        for (uint256 i = 0; i < hubIDs.length; i++) {
            inputAllowed[hubIDs[i]] = allowed[i];
        }
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

    // Override for custom behaviors
    function _userCanEnter(address userAddress)
        internal
        view
        virtual
        returns (bool)
    {
        if (!userIsInHub[userAddress]) {
            return true;
        } else {
            // user already in hub
            return false;
        }
    }

    function _userCanExit(address userAddress)
        internal
        view
        virtual
        returns (bool)
    {
        if (userIsInHub[userAddress]) {
            return true;
        } else {
            // user is not here, cannot exit
            return false;
        }
    }

    function _groupCanEnter(uint256 railcarID)
        internal
        view
        virtual
        returns (bool)
    {
        // todo: verify railcar ID is valid (sender is owner)
        // railcar passengers should all add themselves to car
        if (!groupIsInHub[railcarID]) {
            return true;
        } else {
            // group is already in hub
            return false;
        }
    }

    function _groupCanExit(uint256 railcarID)
        internal
        view
        virtual
        returns (bool)
    {
        if (groupIsInHub[railcarID]) {
            return true;
        } else {
            // group is not here, cannot exit
            return false;
        }
    }

    function _userWillEnter(address userAddress) internal virtual {}

    function _userDidEnter(address userAddress) internal virtual {
        emit UserDidEnter(userAddress);
        userIsInHub[userAddress] = true;
    }

    function _userWillExit(address userAddress) internal virtual {}

    function _userDidExit(address userAddress) internal virtual {
        emit UserDidExit(userAddress);
        userIsInHub[userAddress] = false;
    }

    function _groupWillEnter(uint256 railcarID) internal virtual {}

    function _groupDidEnter(uint256 railcarID) internal virtual {
        emit GroupDidEnter(railcarID);
        groupIsInHub[railcarID] = true;
    }

    function _groupWillExit(uint256 railcarID) internal virtual {}

    function _groupDidExit(uint256 railcarID) internal virtual {
        emit GroupDidExit(railcarID);
        groupIsInHub[railcarID] = false;
    }

    // Internal
    function _startUserHere(address userAddress) internal {
        require(_userCanEnter(userAddress), "user unable to enter");
        _userWillEnter(userAddress);
        _userDidEnter(userAddress);
    }

    function _sendUserToHub(address userAddress, uint256 hubID) internal {
        _userWillExit(userAddress);
        address hubAddress = REGISTRY.hubAddress(hubID);
        Hub(hubAddress).enterUser(userAddress);
        _userDidExit(userAddress);
        emit UserTransited(userAddress, address(this), hubAddress);
    }

    function _sendUserToHub(address userAddress, string memory hubName)
        internal
    {
        _userWillExit(userAddress);
        address hubAddress = REGISTRY.addressFromName(hubName);
        Hub(hubAddress).enterUser(userAddress);
        _userDidExit(userAddress);
        emit UserTransited(userAddress, address(this), hubAddress);
    }

    function _sendGroupToHub(uint256 railcarID, uint256 hubID) internal {
        require(_groupCanExit(railcarID), "group unable to exit");
        _groupWillExit(railcarID);
        address hubAddress = REGISTRY.hubAddress(hubID);
        Hub(hubAddress).enterGroup(railcarID);
        _groupDidExit(railcarID);
        emit GroupTransited(railcarID, address(this), hubAddress);
    }

    function _sendGroupToHub(uint256 railcarID, string memory hubName)
        internal
    {
        require(_groupCanExit(railcarID), "group unable to exit");
        _groupWillExit(railcarID);
        address hubAddress = REGISTRY.addressFromName(hubName);
        Hub(hubAddress).enterGroup(railcarID);
        _groupDidExit(railcarID);
        emit GroupTransited(railcarID, address(this), hubAddress);
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
