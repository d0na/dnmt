// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ChordDHTNode {
    struct NodeInfo {
        address nodeAddress;
        bytes32 nodeId;
        bool active;
    }

    struct Finger {
        bytes32 start; // Inizio intervallo (n + 2^i mod 2^160)
        NodeInfo node; // Successore per questo intervallo
    }

    // Strutture dati Chord
    mapping(bytes32 => bytes32) private _dataStore;
    NodeInfo private _predecessor;
    NodeInfo private _successor;
    Finger[160] private _fingerTable;
    bytes32 private _nodeId;

    event DataStored(bytes32 indexed key, bytes32 value);
    event NodeJoined(address indexed node);
    event TopologyUpdated();

    constructor() {
        _nodeId = keccak256(abi.encodePacked(address(this)));
        _successor = NodeInfo(address(this), _nodeId, true);

        // Inizializza finger table
        for (uint i = 0; i < 160; i++) {
            _fingerTable[i].start = _addMod(_nodeId, 2 ** i);
            _fingerTable[i].node = _successor;
        }
    }

    // ========== FUNZIONI PRINCIPALI ========== //

    /**
     * @notice Unisce il nodo alla rete Chord
     * @param knownNode Un nodo già presente nella rete
     */
    function joinNetwork(address knownNode) external {
        require(knownNode != address(0), "Invalid known node");

        // Trova il successore tramite il nodo conosciuto
        _successor = IChordDHTNode(knownNode).findSuccessor(_nodeId);

        // Notifica il successore del nuovo predecessore
        IChordDHTNode(_successor.nodeAddress).notifyNewPredecessor(
            NodeInfo(address(this), _nodeId, true)
        );

        // Aggiorna la finger table
        _updateFingerTable();

        emit NodeJoined(address(this));
    }

    /**
     * @notice Memorizza dati nella DHT
     */
    function storeAttribute(string calldata key, bytes32 value) external  {
        bytes32 keyHash = keccak256(abi.encodePacked(key));
        address responsibleNode = findSuccessor(keyHash).nodeAddress;

        if (responsibleNode == address(this)) {
            _dataStore[keyHash] = value;
            // emit DataStored(keyHash, value);
        } else {
            IChordDHTNode(responsibleNode).storeAttribute(key, value);
        }
    }

    /**
     * @notice Recupera dati dalla DHT
     */
    function getAttriute(string calldata key) external view returns (bytes32) {
        bytes32 keyHash = keccak256(abi.encodePacked(key));
        require(_dataStore[keyHash] != bytes32(0), "Data not found");
        return _dataStore[keyHash];
    }

    // ========== FUNZIONI DI PROTOCOLLO ========== //

    /**
     * @notice Trova il successore di una chiave
     */
    function findSuccessor(bytes32 key) public view returns (NodeInfo memory) {
        if (_isKeyInRange(key, _nodeId, _successor.nodeId)) {
            return _successor;
        }

        NodeInfo memory closestNode = _closestPrecedingNode(key);
        if (closestNode.nodeAddress == address(this)) {
            return _successor;
        }

        return IChordDHTNode(closestNode.nodeAddress).findSuccessor(key);
    }

    /**
     * @notice Notifica un nuovo predecessore
     */
    function notifyNewPredecessor(NodeInfo calldata newPredecessor) external {
        require(
            msg.sender == _successor.nodeAddress,
            "Unauthorized notification"
        );
        if (
            !_predecessor.active ||
            _isKeyInRange(newPredecessor.nodeId, _predecessor.nodeId, _nodeId)
        ) {
            _predecessor = newPredecessor;
            emit TopologyUpdated();
        }
    }

    /**
     * @notice Stabilizza la rete periodicamente
     */
    function stabilize() external {
        NodeInfo memory suspectedPredecessor = IChordDHTNode(
            _successor.nodeAddress
        ).getPredecessor();

        if (
            suspectedPredecessor.active &&
            _isKeyInRange(
                suspectedPredecessor.nodeId,
                _nodeId,
                _successor.nodeId
            )
        ) {
            _successor = suspectedPredecessor;
        }

        IChordDHTNode(_successor.nodeAddress).notifyNewPredecessor(
            NodeInfo(address(this), _nodeId, true)
        );
    }

    // ========== FUNZIONI DI SUPPORTO ========== //

    function _updateFingerTable() private {
        for (uint i = 0; i < 160; i++) {
            bytes32 start = _addMod(_nodeId, 2 ** i);
            _fingerTable[i].node = findSuccessor(start);
        }
    }

    function _closestPrecedingNode(
        bytes32 key
    ) private view returns (NodeInfo memory) {
        for (uint i = 159; i >= 0; i--) {
            if (
                _fingerTable[i].node.active &&
                _isKeyInRange(_fingerTable[i].node.nodeId, _nodeId, key)
            ) {
                return _fingerTable[i].node;
            }
        }
        return NodeInfo(address(this), _nodeId, true);
    }

    function _isKeyInRange(
        bytes32 key,
        bytes32 a,
        bytes32 b
    ) private pure returns (bool) {
        if (a < b) {
            return key > a && key <= b;
        } else {
            return key > a || key <= b;
        }
    }

    function _addMod(bytes32 a, uint b) private pure returns (bytes32) {
        return bytes32((uint(a) + b) % (2 ** 160));
    }

    // ========== GETTERS ========== //

    function getPredecessor() external view returns (NodeInfo memory) {
        return _predecessor;
    }

    function getSuccessor() external view returns (NodeInfo memory) {
        return _successor;
    }

    function getNodeId() external view returns (bytes32) {
        return _nodeId;
    }
}

interface IChordDHTNode {
    function findSuccessor(
        bytes32 key
    ) external view returns (ChordDHTNode.NodeInfo memory);

    function notifyNewPredecessor(
        ChordDHTNode.NodeInfo calldata newPredecessor
    ) external;

    function getPredecessor()
        external
        view
        returns (ChordDHTNode.NodeInfo memory);

    function storeAttribute(string calldata key, bytes32 value) external view;
}
