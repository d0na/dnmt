// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "hardhat/console.sol";

// Struct per coordinate cross-chain
struct ChainCoordinates {
    uint256 chainId; // EIP-155 Chain ID
    address contractAddress; // Indirizzo del contratto sulla chain remota
}

interface INode {
    function getAttributeValue(
        string memory attribute
    ) external view returns (bytes32, ChainCoordinates memory);

    function findClosestNode(
        string memory attribute
    ) external view returns (address);
}

contract DecentralizedDHTNode {
    // Struct per gli attributi (senza `isLocal`, derivabile da coordinates)
    struct NodeAttribute {
        string attribute;
        bytes32 value;
        ChainCoordinates coordinates; // Se chainId == current chain e contractAddress == address(this), allora è locale
    }

    // Struct per i neighbor (con supporto cross-chain)
    struct Neighbor {
        address nodeAddress;
        bytes32 nodeId;
        bool active;
        ChainCoordinates coordinates;
    }

    // Storage
    mapping(bytes32 => NodeAttribute) public storedAttributes;
    Neighbor[] public neighbors;

    // Eventi
    event AttributeStored(
        string indexed attribute,
        bytes32 value,
        ChainCoordinates coordinates
    );
    event NeighborAdded(
        address nodeAddress,
        bytes32 nodeId,
        ChainCoordinates coordinates
    );
    event NeighborRemoved(address nodeAddress);
    event CrossChainRequest(string attribute, ChainCoordinates target);

    // ========== FUNZIONI PRINCIPALI ========== //

    // Memorizza un attributo LOCALMENTE (automaticamente identificato come locale)
    function storeAttributeLocal(
        string memory attribute,
        bytes32 value
    ) public {
        bytes32 key = keccak256(abi.encodePacked(attribute));

        ChainCoordinates memory localCoords = ChainCoordinates({
            chainId: block.chainid,
            contractAddress: address(this)
        });

        storedAttributes[key] = NodeAttribute(attribute, value, localCoords);
        emit AttributeStored(attribute, value, localCoords);
    }

    // Memorizza un attributo REMOTO (solo coordinate)
    function storeAttributeRemote(
        string memory attribute,
        ChainCoordinates calldata coordinates
    ) public {
        bytes32 key = keccak256(abi.encodePacked(attribute));
        storedAttributes[key] = NodeAttribute(
            attribute,
            bytes32(0),
            coordinates
        );
        emit AttributeStored(attribute, bytes32(0), coordinates);
    }

    // Ottieni il valore e le coordinate di un attributo
    function getAttributeValue(
        string memory attribute
    ) external view returns (bytes32, ChainCoordinates memory) {
        bytes32 key = keccak256(abi.encodePacked(attribute));
        require(
            bytes(storedAttributes[key].attribute).length != 0,
            "Attribute not found"
        );
        return (storedAttributes[key].value, storedAttributes[key].coordinates);
    }

    // ========== GESTIONE NODI NEIGHBOR ========== //

    // Aggiungi un neighbor (può essere su un'altra chain)
    function addNeighbor(
        address nodeAddress,
        bytes32 nodeId,
        ChainCoordinates calldata coordinates
    ) public {
        // Controlla se esiste già e riattivalo
        for (uint i = 0; i < neighbors.length; i++) {
            if (neighbors[i].nodeAddress == nodeAddress) {
                if (!neighbors[i].active) {
                    neighbors[i] = Neighbor(
                        nodeAddress,
                        nodeId,
                        true,
                        coordinates
                    );
                    emit NeighborAdded(nodeAddress, nodeId, coordinates);
                }
                return;
            }
        }

        neighbors.push(Neighbor(nodeAddress, nodeId, true, coordinates));
        emit NeighborAdded(nodeAddress, nodeId, coordinates);
    }

    // Rimuovi un neighbor (mark as inactive)
    function removeNeighbor(address nodeAddress) public {
        for (uint i = 0; i < neighbors.length; i++) {
            if (
                neighbors[i].nodeAddress == nodeAddress && neighbors[i].active
            ) {
                neighbors[i].active = false;
                emit NeighborRemoved(nodeAddress);
                return;
            }
        }
        revert("Neighbor not found or already inactive");
    }

    // ========== QUERY DISTRIBUITE ========== //

    // Trova il nodo più vicino (priorità alla stessa chain)
    function findClosestNode(
        string memory attribute
    ) public view returns (address) {
        // 1. Cerca prima sulla stessa chain
        for (uint i = 0; i < neighbors.length; i++) {
            if (
                neighbors[i].active &&
                neighbors[i].coordinates.chainId == block.chainid
            ) {
                return neighbors[i].nodeAddress;
            }
        }

        // 2. Altrimenti, qualsiasi neighbor attivo
        for (uint i = 0; i < neighbors.length; i++) {
            if (neighbors[i].active) {
                return neighbors[i].nodeAddress;
            }
        }

        return address(0); // Nessun neighbor trovato
    }

    // Risoluzione distribuita (locale -> remota)
    function getDistributedAttribute(
        string memory attribute
    ) public view returns (bytes32, ChainCoordinates memory) {
        bytes32 key = keccak256(abi.encodePacked(attribute));
        NodeAttribute memory attr = storedAttributes[key];

        // Se l'attributo esiste ed è locale, ritorna il valore
        if (
            attr.coordinates.chainId == block.chainid &&
            attr.coordinates.contractAddress == address(this)
        ) {
            return (attr.value, attr.coordinates);
        }

        // Se è registrato come remoto, ritorna le coordinate
        if (bytes(attr.attribute).length != 0) {
            // emit CrossChainRequest(attribute, attr.coordinates);
            return (bytes32(0), attr.coordinates);
        }

        // Altrimenti, interroga i neighbor
        address closestNode = findClosestNode(attribute);
        require(closestNode != address(0), "No active neighbors available");
        return INode(closestNode).getAttributeValue(attribute);
    }

    // ========== UTILITY ========== //

    // Ottieni tutti i neighbor attivi
    function getActiveNeighbors() public view returns (Neighbor[] memory) {
        uint count = 0;
        for (uint i = 0; i < neighbors.length; i++) {
            if (neighbors[i].active) count++;
        }

        Neighbor[] memory activeNeighbors = new Neighbor[](count);
        uint index = 0;
        for (uint i = 0; i < neighbors.length; i++) {
            if (neighbors[i].active) {
                activeNeighbors[index] = neighbors[i];
                index++;
            }
        }
        return activeNeighbors;
    }

    // Helper per verificare se un attributo è locale
    function isAttributeLocal(
        string memory attribute
    ) public view returns (bool) {
        bytes32 key = keccak256(abi.encodePacked(attribute));
        NodeAttribute memory attr = storedAttributes[key];
        return
            attr.coordinates.chainId == block.chainid &&
            attr.coordinates.contractAddress == address(this);
    }
}
