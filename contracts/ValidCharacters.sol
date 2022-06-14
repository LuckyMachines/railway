// SPDX-License-Identifier: MIT
pragma solidity ^0.4.26;

library ValidCharacters {
    struct State {
        bool accepts;
        function(bytes1) internal pure returns (State memory) func;
    }

    string public constant regex = "[a-z0-9._-]";

    function s0(bytes1 c) internal pure returns (State memory) {
        c = c;
        return State(false, s0);
    }

    function s1(bytes1 c) internal pure returns (State memory) {
        if (
            c == 45 ||
            c == 46 ||
            (c >= 48 && c <= 57) ||
            c == 95 ||
            (c >= 97 && c <= 122)
        ) {
            return State(true, s2);
        }

        return State(false, s0);
    }

    function s2(bytes1 c) internal pure returns (State memory) {
        // silence unused var warning
        c = c;

        return State(false, s0);
    }

    function matches(string input) public pure returns (bool) {
        State memory cur = State(false, s1);

        for (uint256 i = 0; i < bytes(input).length; i++) {
            bytes1 c = bytes(input)[i];

            cur = cur.func(c);
        }

        return cur.accepts;
    }
}
