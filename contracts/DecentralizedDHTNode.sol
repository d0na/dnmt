// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "hardhat/console.sol";

struct ChainCoordinates {
    uint256 chainId;
    address contractAddress;
}

interface INode {
    function getAttributeValue(string memory attribute) external view returns (bytes32, ChainCoordinates memory);
    function findClosestNode(string memory attribute) external view returns (address);
}

contract DecentralizedDHTNode {
    struct NodeAttribute {
        string attribute;
        bytes32 value;
        ChainCoordinates coordinates;
    }

    struct Neighbor {
        address nodeAddress;
        bytes32 nodeId;
        ChainCoordinates coordinates;
    }

    mapping(bytes32 => NodeAttribute) public storedAttributes;
    Neighbor[] public neighbors;

    event AttributeStored(string indexed attribute, bytes32 value, ChainCoordinates coordinates);
    event NeighborAdded(address nodeAddress, bytes32 nodeId, ChainCoordinates coordinates);
    event NeighborRemoved(address nodeAddress);
    event CrossChainRequest(string attribute, ChainCoordinates target);

    // ========== FUNZIONI PRINCIPALI ========== //

    function storeAttributeLocal(string memory attribute, bytes32 value) public {
        bytes32 key = keccak256(abi.encodePacked(attribute));
        ChainCoordinates memory localCoords = ChainCoordinates(block.chainid, address(this));
        storedAttributes[key] = NodeAttribute(attribute, value, localCoords);
        emit AttributeStored(attribute, value, localCoords);
    }

    function storeAttributeRemote(string memory attribute, ChainCoordinates calldata coordinates) public {
        bytes32 key = keccak256(abi.encodePacked(attribute));
        storedAttributes[key] = NodeAttribute(attribute, bytes32(0), coordinates);
        emit AttributeStored(attribute, bytes32(0), coordinates);
    }

    function getAttributeValue(string memory attribute) external view returns (bytes32, ChainCoordinates memory) {
        bytes32 key = keccak256(abi.encodePacked(attribute));
        console.log("AA",storedAttributes[key].attribute);
        require(bytes(storedAttributes[key].attribute).length != 0, "Attribute not found");
        return (storedAttributes[key].value, storedAttributes[key].coordinates);
    }

    // ========== GESTIONE NODI NEIGHBOR (SIMPLIFICATA) ========== //

    function addNeighbor(address nodeAddress, bytes32 nodeId, ChainCoordinates calldata coordinates) public {
        // Controlla se esiste già
        for (uint i = 0; i < neighbors.length; i++) {
            if (neighbors[i].nodeAddress == nodeAddress) {
                // Sovrascrive i dati esistenti
                neighbors[i] = Neighbor(nodeAddress, nodeId, coordinates);
                emit NeighborAdded(nodeAddress, nodeId, coordinates);
                return;
            }
        }
        
        neighbors.push(Neighbor(nodeAddress, nodeId, coordinates));
        emit NeighborAdded(nodeAddress, nodeId, coordinates);
    }

    function removeNeighbor(address nodeAddress) public {
        for (uint i = 0; i < neighbors.length; i++) {
            if (neighbors[i].nodeAddress == nodeAddress) {
                // Rimuove spostando l'ultimo elemento (più efficiente)
                neighbors[i] = neighbors[neighbors.length - 1];
                neighbors.pop();
                emit NeighborRemoved(nodeAddress);
                return;
            }
        }
        revert("Neighbor not found");
    }

    // ========== QUERY DISTRIBUITE ========== //

    function findClosestNode(string memory attribute) public view returns (address) {
        if (neighbors.length == 0) return address(0);
        
        // Priorità ai nodi sulla stessa chain
        for (uint i = 0; i < neighbors.length; i++) {
            if (neighbors[i].coordinates.chainId == block.chainid) {
                return neighbors[i].nodeAddress;
            }
        }
        
        // Altrimenti ritorna il primo disponibile
        return neighbors[0].nodeAddress;
    }

    function getDistributedAttribute(string memory attribute) public view returns (bytes32, ChainCoordinates memory) {
        bytes32 key = keccak256(abi.encodePacked(attribute));
        NodeAttribute memory attr = storedAttributes[key];

        // Controllo attributo locale
        if (attr.coordinates.chainId == block.chainid && 
            attr.coordinates.contractAddress == address(this)) {
            return (attr.value, attr.coordinates);
        }

        // Controllo attributo remoto registrato
        if (bytes(attr.attribute).length != 0) {
            return (bytes32(0), attr.coordinates);
        }

        // Query ai neighbors
        address closestNode = findClosestNode(attribute);
        require(closestNode != address(0), "No neighbors available");
        return INode(closestNode).getAttributeValue(attribute);
    }

    // ========== UTILITY ========== //

    function getNeighbors() public view returns (Neighbor[] memory) {
        return neighbors;
    }

    function isAttributeLocal(string memory attribute) public view returns (bool) {
        bytes32 key = keccak256(abi.encodePacked(attribute));
        NodeAttribute memory attr = storedAttributes[key];
        return attr.coordinates.chainId == block.chainid && 
               attr.coordinates.contractAddress == address(this);
    }
}