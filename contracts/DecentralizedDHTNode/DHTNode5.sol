// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "./DecentralizedDHTNode.sol";

contract DHTNode5 is DecentralizedDHTNode {

    constructor() {
        storeAttribute("description", "This is a dnmt description");
    }
}
