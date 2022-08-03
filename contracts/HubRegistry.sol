// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

// NOTE:
/*
This is a simplified version of the registry for local testing only.
Official Hub Registries have been deployed to testnets so HubRegistry contracts 
should not be deployed. This registry does not encompass all of the complex
behavior of the official registry, though it is sufficient for local testing.
*/

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "./ValidCharacters.sol";

contract HubRegistry is AccessControlEnumerableUpgradeable {
    bytes32 public HUB_ROLE;
    bytes32 public TRUST_SCORE_SETTER_ROLE;

    // Mappings from hub name
    mapping(string => address) public addressFromName;
    mapping(string => uint256) public idFromName;

    // Mappings from hub id
    mapping(uint256 => string) public hubName;
    mapping(uint256 => address) public hubAddress;
    mapping(uint256 => uint256) public trustScore;

    // Mapping from hub address
    mapping(address => bool) public isRegistered;
    mapping(address => uint256) public idFromAddress;

    uint256 public totalRegistrations;
    uint256 public registrationFee;
    uint256 public namingFee;

    ValidCharacters private VC;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address adminAddress, address validCharactersAddress)
        public
        initializer
    {
        HUB_ROLE = keccak256("HUB_ROLE");
        TRUST_SCORE_SETTER_ROLE = keccak256("TRUST_SCORE_SETTER_ROLE");
        _setupRole(DEFAULT_ADMIN_ROLE, adminAddress);
        VC = ValidCharacters(validCharactersAddress);
    }

    function hubCanRegister(address _hubAddress)
        public
        view
        returns (bool canRegister)
    {
        canRegister = _canRegister(_hubAddress);
    }

    function nameIsAvailable(string memory _hubName)
        public
        view
        returns (bool available)
    {
        available = idFromName[_hubName] == 0 ? true : false;
    }

    function hubAddressesInRange(uint256 startingID, uint256 maxID)
        public
        view
        returns (address[] memory)
    {
        require(startingID <= totalRegistrations, "starting ID out of bounds");
        require(maxID >= startingID, "maxID < startingID");
        // require starting ID exists
        uint256 actualMaxID = maxID;
        uint256 size = actualMaxID - startingID + 1;
        address[] memory hubs = new address[](size);
        for (uint256 i = startingID; i < startingID + size; i++) {
            uint256 index = startingID - i;
            hubs[index] = hubAddress[i];
        }
        return hubs;
    }

    // Called directly from hub
    function register() external payable {
        require(_canRegister(_msgSender()), "Hub not qualified to register");
        require(msg.value >= registrationFee, "registration fee required");
        _register(_msgSender());
    }

    function setName(string memory _hubName, uint256 hubID)
        external
        payable
        onlyRole(HUB_ROLE)
    {
        require(VC.matches(_hubName));
        require(msg.value >= namingFee, "naming fee required");
        require(_msgSender() == hubAddress[hubID], "hubID for sender is wrong");
        require(nameIsAvailable(_hubName), "name unavailable");
        addressFromName[_hubName] = hubAddress[hubID];
        idFromName[_hubName] = hubID;
        hubName[hubID] = _hubName;
    }

    // Trust Score Setter
    function setTrustScore(uint256 score, uint256 hubID)
        external
        onlyRole(TRUST_SCORE_SETTER_ROLE)
    {
        trustScore[hubID] = score;
    }

    // Admin
    function setRegistrationFee(uint256 fee)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        registrationFee = fee;
    }

    function setNamingFee(uint256 fee) public onlyRole(DEFAULT_ADMIN_ROLE) {
        registrationFee = fee;
    }

    // Internal
    function _register(address _hubAddress) internal {
        if (!isRegistered[_hubAddress]) {
            isRegistered[_hubAddress] = true;
            uint256 newID = totalRegistrations + 1; // IDs start @ 1
            totalRegistrations = newID;
            hubAddress[newID] = _hubAddress;
            idFromAddress[_hubAddress] = newID;
            _setupRole(HUB_ROLE, _hubAddress);
        }
    }

    function _canRegister(address _hubAddress)
        internal
        view
        virtual
        returns (bool canRegister)
    {
        canRegister = (_hubAddress == address(0)) ? false : true;
    }
}
