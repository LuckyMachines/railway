// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract StakingToken is ERC20 {
    constructor(address dexAddress) ERC20("StakingToken", "STK") {
        // Mint to sample DEX for liquidity
        _mint(dexAddress, 100000 * 10**decimals());
    }
}
