//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./StakingToken.sol";
import "../../Hub.sol";

contract Stake is Hub {
    StakingToken private STAKING_TOKEN;

    // mapping from staker address
    mapping(address => uint256) public stakedBalance;

    constructor(
        address stakingTokenAddress,
        address hubRegistryAddress,
        address hubAdmin
    ) Hub(hubRegistryAddress, hubAdmin) {
        STAKING_TOKEN = StakingToken(stakingTokenAddress);
        uint256 hubID = REGISTRY.idFromAddress(address(this));
        REGISTRY.setName("sample.stake", hubID);
    }

    function stakeTokens(uint256 amount) public {
        // requires this contract allowed to spend amount
        STAKING_TOKEN.transferFrom(msg.sender, address(this), amount);
        stakedBalance[msg.sender] += amount;
    }

    function stakeTokensFor(address staker, uint256 amount) public {
        // requires this contract allowed to spend amount on behalf of staker
        STAKING_TOKEN.transferFrom(staker, address(this), amount);
        stakedBalance[staker] += amount;
    }

    function getBalance() public view returns (uint256 balance) {
        balance = stakedBalance[msg.sender];
    }

    function stakedBalanceOf(address stakerAddress)
        public
        view
        returns (uint256 balance)
    {
        balance = stakedBalance[stakerAddress];
    }

    // Automatic actions from railway
    function _userDidEnter(address userAddress) internal override {
        // Stake 0.01 Tokens
        stakeTokensFor(userAddress, 0.01 ether);
        _sendUserToHub(userAddress, "sample.exclusive-nft");
    }
}
