// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "./DecentralizedDHTNode.sol";

contract DHTNode1 is DecentralizedDHTNode {
    bytes32 public assetId = 0x706970706f000000000000000000000000000000000000000000000000000000;

    constructor() {
        // Questo nodo ha un valore locale per l'attributo "material"
        storeAttributeLocal( "protection", "100");
    }
}
