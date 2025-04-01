// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "./ChordDHTNode.sol";

contract ChordDHTNode3 is ChordDHTNode {

    constructor() {
        this.storeAttribute("power", "2000"); 
    }
}
