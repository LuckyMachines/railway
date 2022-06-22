//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./StakingToken.sol";
import "../../Hub.sol";

// exchange native token for StakingToken at 1:1

contract DEX is Hub {
    StakingToken private STAKING_TOKEN;

    mapping(address => uint256) public prepaidBalance;

    constructor(address hubRegistryAddress, address hubAdmin)
        Hub(hubRegistryAddress, hubAdmin)
    {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        uint256 hubID = REGISTRY.idFromAddress(address(this));
        REGISTRY.setName("sample.dex", hubID);
    }

    // Set this after tokens have been minted
    function setStakingTokenAddress(address stakingTokenAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        STAKING_TOKEN = StakingToken(stakingTokenAddress);
    }

    function exchange() public payable {
        require(
            STAKING_TOKEN.balanceOf(address(this)) >= msg.value,
            "not enough liquidity"
        );
        STAKING_TOKEN.transfer(msg.sender, msg.value);
    }

    function prepay(address user) external payable {
        prepaidBalance[user] += msg.value;
    }

    // Automatic actions from railway
    function _userDidEnter(address userAddress) internal override {
        STAKING_TOKEN.transfer(userAddress, prepaidBalance[userAddress]);
        prepaidBalance[userAddress] = 0;
        _sendUserToHub(userAddress, "sample.stake");
    }
}
