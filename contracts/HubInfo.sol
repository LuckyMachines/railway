// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

import "./Hub.sol";

library HubInfo {
    function outputs(address hubAddress)
        public
        view
        returns (
            string[] memory outputNames,
            address[] memory outputAddresses,
            uint256[] memory trustScores
        )
    {
        Hub HUB = Hub(hubAddress);
        HubRegistry REGISTRY = HUB.REGISTRY();
        uint256[] memory hOutputs = HUB.hubOutputs(); // output IDs
        outputNames = new string[](hOutputs.length);
        outputAddresses = new address[](hOutputs.length);
        trustScores = new uint256[](hOutputs.length);
        for (uint256 i = 0; i < hOutputs.length; i++) {
            outputNames[i] = REGISTRY.hubName(hOutputs[i]);
            outputAddresses[i] = REGISTRY.hubAddress(hOutputs[i]);
            trustScores[i] = REGISTRY.trustScore(hOutputs[i]);
        }
    }
}
