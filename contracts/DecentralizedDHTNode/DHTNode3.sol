// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "./DecentralizedDHTNode.sol";

contract DHTNode3 is DecentralizedDHTNode {

    constructor() {
        storeAttribute("power", "2000"); 
    }
}
