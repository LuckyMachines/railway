//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./Stake.sol";
import "../../Hub.sol";
import "./DEX.sol";

contract NFTDefiHub is Hub {
    IERC20 internal STAKING_TOKEN;
    IERC721 internal EXCLUSIVE_NFT;
    Stake internal STAKE;

    address[] _partyGuests;
    mapping(address => bool) public atParty;

    constructor(
        address stakingTokenAddress,
        address exclusiveNFTAddress,
        address stakingAddress,
        address hubRegistryAddress,
        address hubAdmin
    ) Hub(hubRegistryAddress, hubAdmin) {
        STAKING_TOKEN = IERC20(stakingTokenAddress);
        EXCLUSIVE_NFT = IERC721(exclusiveNFTAddress);
        STAKE = Stake(stakingAddress);
        uint256 hubID = REGISTRY.idFromAddress(address(this));
        REGISTRY.setName("sample.main-hub", hubID);
    }

    function getTokenSummary()
        public
        view
        returns (
            uint256 nativeTokenBalance,
            uint256 stakingTokenBalance,
            uint256 tokensStaked,
            uint256 exclusiveNFTBalance
        )
    {
        nativeTokenBalance = msg.sender.balance;
        stakingTokenBalance = STAKING_TOKEN.balanceOf(msg.sender);
        tokensStaked = STAKE.stakedBalanceOf(msg.sender);
        exclusiveNFTBalance = EXCLUSIVE_NFT.balanceOf(msg.sender);
    }

    function claimNFT() public payable {
        require(
            msg.value >= 100000000000000000,
            "send at least 0.1 eth with tx"
        );
        DEX(REGISTRY.addressFromName("sample.dex")).prepay{value: (msg.value)}(
            msg.sender
        );

        // send to next hub on railway
        _sendUserToHub(msg.sender, "sample.dex");
    }

    function getPartyGuests() public view returns (address[] memory) {
        return _partyGuests;
    }

    function attemptPartyEntry() public {
        require(
            EXCLUSIVE_NFT.balanceOf(msg.sender) > 0,
            "Exclusive NFT required for entry"
        );
        if (!atParty[msg.sender]) {
            _partyGuests.push(msg.sender);
            atParty[msg.sender] = true;
        }
    }

    function attemptPartyEntryFor(address userAddress) internal {
        if (EXCLUSIVE_NFT.balanceOf(userAddress) > 0) {
            if (!atParty[userAddress]) {
                _partyGuests.push(userAddress);
                atParty[userAddress] = true;
            }
        }
    }

    // Automatic actions from railway
    function _userDidEnter(address userAddress) internal override {
        attemptPartyEntryFor(userAddress);
    }
}
