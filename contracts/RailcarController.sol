// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "./RailYard.sol";

contract RailcarController is AccessControlEnumerable {
    bytes32 public constant HUB_ROLE = keccak256("HUB_ROLE");
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
}

// add member
// remove member

// set auto-run map?
// start auto-run
// stop auto-run
