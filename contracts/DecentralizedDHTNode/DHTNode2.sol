// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "./DecentralizedDHTNode.sol";

contract DHTNode2 is DecentralizedDHTNode {

    constructor() {
        storeAttribute("name", "NMT on DHTnode2");
    }
}
