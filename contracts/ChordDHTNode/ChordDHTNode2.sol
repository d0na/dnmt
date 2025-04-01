// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "./ChordDHTNode.sol";

contract ChordDHTNode2 is ChordDHTNode {
    constructor() {
        // Questo nodo ha un valore locale per l'attributo "material"
        this.storeAttribute("name", "NMT on DHTnode2");
    }
}