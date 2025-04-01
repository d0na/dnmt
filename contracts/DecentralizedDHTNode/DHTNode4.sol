// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "./DecentralizedDHTNode.sol";

contract DHTNode4 is DecentralizedDHTNode {

    constructor() {
        storeAttribute("health", "50");
    }
}
