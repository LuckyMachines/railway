// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

// Members can join a group railcar
// or Hub can create one with specific addresses

contract RailYard is AccessControlEnumerable {
    bytes32 public constant HUB_ROLE = keccak256("HUB_ROLE");
    bytes32 public constant RAILCAR_CONTROLLER =
        keccak256("RAILCAR_CONTROLLER");

    struct Railcar {
        address[] members;
        uint256 memberLimit;
        address owner;
        mapping(address => bool) isMember;
        mapping(address => uint256) memberIndex; // for removing members without looping
    }

    // Mappings from railcar id
    mapping(uint256 => Railcar) public railcar;

    // Mapping from member address
    mapping(address => uint256[]) public railcars;
    mapping(address => uint256[]) public ownedRailcars;

    uint256 public totalRailcars;
    uint256 public creationFee;

    constructor(address adminAddress) {
        _setupRole(DEFAULT_ADMIN_ROLE, adminAddress);
    }

    function canCreateRailcar(address _address)
        public
        view
        returns (bool canCreate)
    {
        canCreate = _canCreate(_address);
    }

    function createRailcar(uint256 limit)
        public
        payable
        returns (uint256 railcarID)
    {
        require(_canCreate(_msgSender()), "Sender not qualified to create");
        require(msg.value >= creationFee, "Creation fee required");
        _createRailcar(_msgSender(), limit);
        railcarID = totalRailcars;
    }

    function createRailcar(address[] memory _members)
        external
        payable
        returns (uint256 railcarID)
    {
        require(_canCreate(_msgSender()), "Sender not qualified to create");
        require(msg.value >= creationFee, "Creation fee required");
        _createRailcar(_msgSender(), _members.length, _members);
        railcarID = totalRailcars;
    }

    function getCreatedRailcars() public view returns (uint256[] memory) {
        return ownedRailcars[_msgSender()];
    }

    function getRailcars() public view returns (uint256[] memory) {
        return railcars[_msgSender()];
    }

    // Called directly from hub
    function createRailcarFromHub(address[] memory _members)
        external
        payable
        onlyRole(HUB_ROLE)
        returns (uint256 railcarID)
    {
        require(_canCreate(_msgSender()), "Hub not qualified to create");
        require(msg.value >= creationFee, "Creation fee required");
        _createRailcar(_msgSender(), _members.length, _members);
        railcarID = totalRailcars;
    }

    // Railcar Controller (controller called by hub or railcar railcar member)
    function joinRailcar(uint256 railcarID, address userAddress)
        public
        onlyRole(RAILCAR_CONTROLLER)
    {
        _joinRailcar(railcarID, userAddress);
    }

    function leaveRailcar(uint256 railcarID, address userAddress)
        public
        onlyRole(RAILCAR_CONTROLLER)
    {
        _leaveRailcar(railcarID, userAddress);
    }

    // Admin
    function setCreationFee(uint256 fee) public onlyRole(DEFAULT_ADMIN_ROLE) {
        creationFee = fee;
    }

    // Internal
    function _createRailcar(address _creatorAddress, uint256 limit) internal {
        totalRailcars++;
        Railcar storage r = railcar[totalRailcars];
        r.memberLimit = limit;
        r.owner = _creatorAddress;
        ownedRailcars[_creatorAddress].push(totalRailcars);
    }

    function _createRailcar(
        address _creatorAddress,
        uint256 limit,
        address[] memory _members
    ) internal {
        // Create a railcar with members
        _createRailcar(_creatorAddress, limit);
        uint256 validMembers = limit < _members.length
            ? limit
            : _members.length;
        for (uint256 i = 0; i < validMembers; i++) {
            _joinRailcar(totalRailcars, _members[i]);
        }
    }

    function _canCreate(address _hubAddress)
        internal
        view
        virtual
        returns (bool canCreate)
    {
        canCreate = (_hubAddress == address(0)) ? false : true;
    }

    function _joinRailcar(uint256 railcarID, address userAddress) internal {
        Railcar storage r = railcar[railcarID];
        if (!r.isMember[userAddress]) {
            r.members.push(userAddress);
            r.memberIndex[userAddress] = r.members.length - 1;
            r.isMember[userAddress] = true;
            railcars[userAddress].push(railcarID);
        }
    }

    function _leaveRailcar(uint256 railcarID, address userAddress) internal {
        Railcar storage r = railcar[railcarID];
        if (!r.isMember[userAddress]) {
            delete r.members[r.memberIndex[userAddress]];
            r.isMember[userAddress] = false;
            r.memberIndex[userAddress] = 0;
            // TODO:
            // delete from array of railcars - railcars[userAddress] will still have railcar ID
        }
    }
}
