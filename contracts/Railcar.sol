// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract Railcar is AccessControlEnumerable {
    bytes32 public constant HUB_ROLE = keccak256("HUB_ROLE");

    // Mappings from railcar id
    mapping(uint256 => address[]) public members;
    mapping(uint256 => uint256) public memberLimit;
    mapping(uint256 => address) public creator;

    // Mapping from member address
    mapping(address => uint256[]) public railcars;
    mapping(address => uint256[]) public createdRailcars;

    // Mapping from railcar id -> member address
    mapping(uint256 => mapping(address => bool)) public isMember;

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

    function createRailcar(uint256 limit) public payable {
        require(_canCreate(_msgSender()), "Sender not qualified to create");
        require(msg.value >= creationFee, "Creation fee required");
        _createRailcar(_msgSender(), limit);
    }

    function getCreatedRailcars() public view returns (uint256[] memory) {
        return createdRailcars[_msgSender()];
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
        require(_canCreate(_msgSender()), "Hub not qualified to register");
        require(msg.value >= creationFee, "Creation fee required");
        _createRailcar(_msgSender(), _members.length, _members);
        railcarID = totalRailcars;
    }

    // Admin
    function setRegistrationFee(uint256 fee)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        creationFee = fee;
    }

    // Internal
    function _createRailcar(address _creatorAddress, uint256 limit) internal {
        totalRailcars++;
        memberLimit[totalRailcars] = limit;
        creator[totalRailcars] = _creatorAddress;
        createdRailcars[_creatorAddress].push(totalRailcars);
    }

    function _createRailcar(
        address _creatorAddress,
        uint256 limit,
        address[] memory _members
    ) internal {
        _createRailcar(_creatorAddress, limit);
        uint256 validMembers = limit < _members.length
            ? limit
            : _members.length;
        for (uint256 i = 0; i < validMembers; i++) {
            if (!isMember[totalRailcars][_members[i]]) {
                members[totalRailcars].push(_members[i]);
                railcars[_members[i]].push(totalRailcars);
                isMember[totalRailcars][_members[i]] = true;
            }
        }
    }

    function _canCreate(address _hubAddress)
        internal
        view
        virtual
        returns (bool canRegister)
    {
        canRegister = (_hubAddress == address(0)) ? false : true;
    }
}
