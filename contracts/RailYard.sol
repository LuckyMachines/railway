// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

// Members can join a group railcar
// or Hub can create one with specific addresses

contract RailYard is AccessControlEnumerable {
    struct Railcar {
        address[] members;
        uint256 memberLimit;
        address owner;
        address operator;
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

    // Railcar Owner functions
    function setOperator(address operator, uint256 railcarID) public {
        Railcar storage r = railcar[railcarID];
        require(r.owner == _msgSender(), "only owner can assign operator");
        r.operator = operator;
    }

    // Railcar Owner / Operator functions
    function joinRailcar(uint256 railcarID, address userAddress) public {
        require(
            railcar[railcarID].owner == _msgSender() ||
                railcar[railcarID].operator == _msgSender(),
            "only owner or operator can call joinRailcar directly"
        );
        _joinRailcar(railcarID, userAddress);
    }

    function leaveRailcar(uint256 railcarID, address userAddress) public {
        require(
            railcar[railcarID].owner == _msgSender() ||
                railcar[railcarID].operator == _msgSender(),
            "only owner or operator can call leaveRailcar directly"
        );
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
        r.operator = _creatorAddress;
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

    function _canCreate(address creatorAddress)
        internal
        view
        virtual
        returns (bool canCreate)
    {
        canCreate = (creatorAddress == address(0)) ? false : true;
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
