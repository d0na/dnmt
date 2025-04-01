// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "./ChordDHTNode.sol";

contract ChordDHTNode1 is ChordDHTNode {
    constructor() {
        // Questo nodo ha un valore locale per l'attributo "material"
        this.storeAttribute("protection", "100");
    }
}
