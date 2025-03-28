// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "./DecentralizedDHTNode.sol";

contract DHTNode2 is DecentralizedDHTNode {
    bytes32 public assetId =
        0x706970706f000000000000000000000000000000000000000000000000000000;

    constructor() {
        storeAttributeLocal("name", "NMT on DHTnode2");
    }
}
