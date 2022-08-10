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
        uint256[] intStorage;
        string[] stringStorage;
    }

    // Mappings from railcar id
    mapping(uint256 => Railcar) public railcar;

    // Mapping from member address
    mapping(address => uint256[]) public railcars;
    mapping(address => uint256[]) public ownedRailcars;

    // Mapping from railcar id => member address
    mapping(uint256 => mapping(address => bool)) public isMember;
    mapping(uint256 => mapping(address => uint256)) public memberIndex;

    uint256 public totalRailcars;
    uint256 public creationFee;
    uint256 public storageFee;

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
        _createRailcar(_msgSender(), _msgSender(), limit);
        railcarID = totalRailcars;
    }

    function createRailcar(uint256 limit, uint256[] memory storageValues)
        public
        payable
        returns (uint256 railcarID)
    {
        require(_canCreate(_msgSender()), "Sender not qualified to create");
        require(msg.value >= creationFee, "Creation fee required");
        _createRailcar(_msgSender(), _msgSender(), limit, storageValues);
        railcarID = totalRailcars;
    }

    function createRailcar(address[] memory _members)
        external
        payable
        returns (uint256 railcarID)
    {
        require(_canCreate(_msgSender()), "Sender not qualified to create");
        require(msg.value >= creationFee, "Creation fee required");
        _createRailcar(_msgSender(), _msgSender(), _members.length, _members);
        railcarID = totalRailcars;
    }

    function createRailcar(
        address ownerAddress,
        address operatorAddress,
        uint256 limit
    ) public payable returns (uint256 railcarID) {
        require(_canCreate(_msgSender()), "Sender not qualified to create");
        require(msg.value >= creationFee, "Creation fee required");
        _createRailcar(ownerAddress, operatorAddress, limit);
        railcarID = totalRailcars;
    }

    function createRailcar(
        address ownerAddress,
        address operatorAddress,
        address[] memory _members
    ) external payable returns (uint256 railcarID) {
        require(_canCreate(_msgSender()), "Sender not qualified to create");
        require(msg.value >= creationFee, "Creation fee required");
        _createRailcar(
            ownerAddress,
            operatorAddress,
            _members.length,
            _members
        );
        railcarID = totalRailcars;
    }

    function getCreatedRailcars() public view returns (uint256[] memory) {
        return ownedRailcars[_msgSender()];
    }

    function getRailcars() public view returns (uint256[] memory) {
        return railcars[_msgSender()];
    }

    // Railcar summary functions
    // struct Railcar {
    //     address[] members;
    //     uint256 memberLimit;
    //     address owner;
    //     address operator;
    //     mapping(address => bool) isMember;
    //     mapping(address => uint256) memberIndex; // for removing members without looping
    //     uint256[] intStorage;
    //     string[] stringStorage;
    // }
    function getRailcarMembers(uint256 railcarID)
        public
        view
        returns (address[] memory)
    {
        return railcar[railcarID].members;
    }

    function getRailcarMemberLimit(uint256 railcarID)
        public
        view
        returns (uint256)
    {
        return railcar[railcarID].memberLimit;
    }

    function getRailcarOwner(uint256 railcarID) public view returns (address) {
        return railcar[railcarID].owner;
    }

    function getRailcarOperator(uint256 railcarID)
        public
        view
        returns (address)
    {
        return railcar[railcarID].operator;
    }

    function getRailcarIsMemeber(uint256 railcarID, address userAddress)
        public
        view
        returns (bool)
    {
        return isMember[railcarID][userAddress];
    }

    function getRailcarMemberIndex(uint256 railcarID, address userAddress)
        public
        view
        returns (uint256)
    {
        return memberIndex[railcarID][userAddress];
    }

    function getRailcarIntStorage(uint256 railcarID)
        public
        view
        returns (uint256[] memory)
    {
        return railcar[railcarID].intStorage;
    }

    function getRailcarStringStorage(uint256 railcarID)
        public
        view
        returns (string[] memory)
    {
        return railcar[railcarID].stringStorage;
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

    function addStorage(uint256 railcarID, string[] memory strings)
        public
        payable
    {
        require(
            railcar[railcarID].owner == _msgSender() ||
                railcar[railcarID].operator == _msgSender(),
            "only owner or operator can add storage"
        );
        require(msg.value >= storageFee, "Storage fee required");
        Railcar storage r = railcar[railcarID];
        r.stringStorage = strings;
    }

    function addStorage(uint256 railcarID, uint256[] memory ints)
        public
        payable
    {
        require(msg.value >= storageFee, "Storage fee required");
        require(
            railcar[railcarID].owner == _msgSender() ||
                railcar[railcarID].operator == _msgSender(),
            "only owner or operator can add storage"
        );
        Railcar storage r = railcar[railcarID];
        r.intStorage = ints;
    }

    // Admin
    function setCreationFee(uint256 fee) public onlyRole(DEFAULT_ADMIN_ROLE) {
        creationFee = fee;
    }

    function setStorageFee(uint256 fee) public onlyRole(DEFAULT_ADMIN_ROLE) {
        storageFee = fee;
    }

    // Internal
    function _createRailcar(
        address _ownerAddress,
        address _operatorAddress,
        uint256 limit
    ) internal {
        totalRailcars++;
        Railcar storage r = railcar[totalRailcars];
        r.memberLimit = limit;
        r.owner = _ownerAddress;
        r.operator = _operatorAddress;
        ownedRailcars[_ownerAddress].push(totalRailcars);
    }

    function _createRailcar(
        address _ownerAddress,
        address _operatorAddress,
        uint256 limit,
        uint256[] memory storageValues
    ) internal {
        totalRailcars++;
        Railcar storage r = railcar[totalRailcars];
        r.memberLimit = limit;
        r.owner = _ownerAddress;
        r.operator = _operatorAddress;
        r.intStorage = storageValues;
        ownedRailcars[_ownerAddress].push(totalRailcars);
    }

    function _createRailcar(
        address _ownerAddress,
        address _operatorAddress,
        uint256 limit,
        string[] memory storageValues
    ) internal {
        totalRailcars++;
        Railcar storage r = railcar[totalRailcars];
        r.memberLimit = limit;
        r.owner = _ownerAddress;
        r.operator = _operatorAddress;
        r.stringStorage = storageValues;
        ownedRailcars[_ownerAddress].push(totalRailcars);
    }

    function _createRailcar(
        address _ownerAddress,
        address _operatorAddress,
        uint256 limit,
        address[] memory _members
    ) internal {
        // Create a railcar with members
        _createRailcar(_ownerAddress, _operatorAddress, limit);
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
        if (!isMember[railcarID][userAddress]) {
            Railcar storage r = railcar[railcarID];
            r.members.push(userAddress);
            memberIndex[railcarID][userAddress] = r.members.length - 1;
            isMember[railcarID][userAddress] = true;
            railcars[userAddress].push(railcarID);
        }
    }

    function _leaveRailcar(uint256 railcarID, address userAddress) internal {
        if (!isMember[railcarID][userAddress]) {
            Railcar storage r = railcar[railcarID];
            delete r.members[memberIndex[railcarID][userAddress]];
            isMember[railcarID][userAddress] = false;
            memberIndex[railcarID][userAddress] = 0;
            // TODO:
            // delete from array of railcars - railcars[userAddress] will still have railcar ID
        }
    }
}
