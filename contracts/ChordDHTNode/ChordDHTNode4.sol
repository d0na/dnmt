// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "./ChordDHTNode.sol";

contract ChordDHTNode4 is ChordDHTNode {
    constructor() {
        this.storeAttribute("health", "50");
    }
}
