// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./Stake.sol";
import "../../Hub.sol";

//This contract allows a user to mint an exclusive NFT if they are staking at least .01 StakingToken on Stake.sol

contract ExclusiveNFT is ERC721, Ownable, Hub {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    Stake private STAKE;

    uint256 constant stakedBalanceRequired = 10000000000000000; // 0.01

    constructor(
        address stakingAddress,
        address hubRegistryAddress,
        address hubAdmin
    ) ERC721("ExclusiveNFT", "XNFT") Hub(hubRegistryAddress, hubAdmin) {
        STAKE = Stake(stakingAddress);
        uint256 hubID = REGISTRY.idFromAddress(address(this));
        REGISTRY.setName("sample.exclusive-nft", hubID);
    }

    function mint() public {
        require(
            STAKE.stakedBalanceOf(msg.sender) >= stakedBalanceRequired,
            "minimum staking not met"
        );
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
    }

    function mintFor(address userAddress) internal {
        require(
            STAKE.stakedBalanceOf(userAddress) >= stakedBalanceRequired,
            "minimum staking not met"
        );
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(userAddress, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, AccessControlEnumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // Automatic actions from railway
    function _userDidEnter(address userAddress) internal override {
        mintFor(userAddress);
        _sendUserToHub(userAddress, "sample.main-hub");
    }
}
