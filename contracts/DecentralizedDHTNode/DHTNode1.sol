// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "./DecentralizedDHTNode.sol";

contract DHTNode1 is DecentralizedDHTNode {
    constructor() {
        // Questo nodo ha un valore locale per l'attributo "material"
        storeAttribute( "protection", "100");
    }
}
