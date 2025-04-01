interface INode {
    function getAttributeValue(string memory attribute) external view returns (bytes32);
    function findClosestNode(string memory attribute) external view returns (address);
}

contract DecentralizedDHTNode {
    struct Neighbor {
        address nodeAddress;
        bytes32 nodeId;
        bool active;
    }

    struct NodeAttribute {
        string attribute;
        bytes32 value;
    }

    mapping(bytes32 => NodeAttribute) public storedAttributes;
    Neighbor[] public neighbors;

    event AttributeStored(string indexed attribute, bytes32 value);
    event NeighborAdded(address nodeAddress, bytes32 nodeId);
    event NeighborRemoved(address nodeAddress);

    function storeAttribute(string memory attribute, bytes32 value) public {
        bytes32 key = keccak256(abi.encodePacked(attribute));
        storedAttributes[key] = NodeAttribute(attribute, value);
        emit AttributeStored(attribute, value);
    }

    function getAttributeValue(string memory attribute) external view returns (bytes32) {
        bytes32 key = keccak256(abi.encodePacked(attribute));
        require(storedAttributes[key].value != bytes32(0), "Attribute not found");
        return storedAttributes[key].value;
    }

    function addNeighbor(address nodeAddress, bytes32 nodeId) public {
        // Check if neighbor already exists
        for (uint i = 0; i < neighbors.length; i++) {
            if (neighbors[i].nodeAddress == nodeAddress) {
                // Reactivate if previously removed
                if (!neighbors[i].active) {
                    neighbors[i].active = true;
                    neighbors[i].nodeId = nodeId;
                    emit NeighborAdded(nodeAddress, nodeId);
                }
                return;
            }
        }
        
        neighbors.push(Neighbor(nodeAddress, nodeId, true));
        emit NeighborAdded(nodeAddress, nodeId);
    }

    function removeNeighbor(address nodeAddress) public {
        for (uint i = 0; i < neighbors.length; i++) {
            if (neighbors[i].nodeAddress == nodeAddress && neighbors[i].active) {
                neighbors[i].active = false;
                emit NeighborRemoved(nodeAddress);
                return;
            }
        }
        revert("Neighbor not found or already inactive");
    }

    function findClosestNode(string memory attribute) public view returns (address) {
        // Simple implementation - returns first active neighbor
        // In a real DHT, this would use distance metrics
        for (uint i = 0; i < neighbors.length; i++) {
            if (neighbors[i].active) {
                return neighbors[i].nodeAddress;
            }
        }
        return address(0);
    }

    function getDistributedAttribute(string memory attribute) public view returns (bytes32) {
        bytes32 key = keccak256(abi.encodePacked(attribute));
        if (storedAttributes[key].value != bytes32(0)) {
            return storedAttributes[key].value;
        }
        
        address closestNode = findClosestNode(attribute);
        require(closestNode != address(0), "No active neighbors available");
        return INode(closestNode).getAttributeValue(attribute);
    }

    function getActiveNeighbors() public view returns (Neighbor[] memory) {
        uint activeCount = 0;
        for (uint i = 0; i < neighbors.length; i++) {
            if (neighbors[i].active) {
                activeCount++;
            }
        }
        
        Neighbor[] memory activeNeighbors = new Neighbor[](activeCount);
        uint index = 0;
        for (uint i = 0; i < neighbors.length; i++) {
            if (neighbors[i].active) {
                activeNeighbors[index] = neighbors[i];
                index++;
            }
        }
        return activeNeighbors;
    }
}