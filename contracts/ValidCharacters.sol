// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract ValidCharacters {
    struct State {
        bool accepts;
        function(bytes1) internal pure returns (State memory) func;
    }

    string public constant regex = "[a-z0-9._-]+";

    function s0(bytes1 c) internal pure returns (State memory) {
        c = c;
        return State(false, s0);
    }

    function s1(bytes1 c) internal pure returns (State memory) {
        uint8 uc = uint8(c);
        if (
            uc == 45 ||
            uc == 46 ||
            (uc >= 48 && uc <= 57) ||
            uc == 95 ||
            (uc >= 97 && uc <= 122)
        ) {
            return State(true, s2);
        }

        return State(false, s0);
    }

    function s2(bytes1 c) internal pure returns (State memory) {
        uint8 uc = uint8(c);
        if (
            uc == 45 ||
            uc == 46 ||
            (uc >= 48 && uc <= 57) ||
            uc == 95 ||
            (uc >= 97 && uc <= 122)
        ) {
            return State(true, s3);
        }

        return State(false, s0);
    }

    function s3(bytes1 c) internal pure returns (State memory) {
        uint8 uc = uint8(c);
        if (
            uc == 45 ||
            uc == 46 ||
            (uc >= 48 && uc <= 57) ||
            uc == 95 ||
            (uc >= 97 && uc <= 122)
        ) {
            return State(true, s3);
        }

        return State(false, s0);
    }

    function matches(string memory input) public pure returns (bool) {
        State memory cur = State(false, s1);

        for (uint256 i = 0; i < bytes(input).length; i++) {
            bytes1 c = bytes(input)[i];

            cur = cur.func(c);
        }

        return cur.accepts;
    }
}
