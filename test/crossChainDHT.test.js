const { expect } = require("chai");
const { ethers, network } = require("hardhat");

describe("DecentralizedDHTNode - Cross Chain", function () {
    let dhtNode1, dhtNode2;
    let owner, addr1;
    let provider1, provider2;
    let wallet1, wallet2;

    // Coordinate per le chain simulate
    const chain1 = {
        id: 31337,
        name: "hardhat"
    };

    const chain2 = {
        id: 31338,
        name: "hardhat2"
    };

    before(async function () {
        [owner, account1, account2] = await ethers.getSigners();

        provider1 = new ethers.JsonRpcProvider("http://127.0.0.1:8545");
        provider2 = new ethers.JsonRpcProvider("http://127.0.0.1:8546");
      
        wallet1 = account1.connect(provider1);
        wallet2 = account2.connect(provider2);

        
        // Deploy DHTNode1 chain principale
        const DHTNode1 = await ethers.getContractFactory("DHTNode1");
        const nonce1 = await provider1.getTransactionCount(wallet1.address);
        dhtNode1 = await DHTNode1.connect(wallet1).deploy();

        console.log("Node 1 deployed to:", dhtNode1.target);

        // Deploy DHTNode2 seconda chain
        const DHTNode2 = await ethers.getContractFactory("DHTNode2");
        const nonce2 = await provider1.getTransactionCount(wallet1.address);
        dhtNode2 = await DHTNode2.deploy();

        console.log("Node 2 deployed to:", dhtNode2.target);
    })
    it("Dovrebbe registrare correttamente un attributo locale", async function () {
        await dhtNode1.storeAttributeLocal("temperature", ethers.encodeBytes32String("25"));

        const [value, coordinates] = await dhtNode1.getAttributeValue("temperature");
        console.log("coord:", coordinates);
        expect(ethers.decodeBytes32String(value)).to.equal("25");
        console.log("value:", coordinates.isLocal);
        // expect(coordinates.isLocal).to.be.true;
        expect(coordinates.chainId).to.equal(chain1.id);
    });

    it("Dovrebbe registrare correttamente un attributo remoto", async function () {
        const remoteCoordinates = {
            chainId: chain2.id,
            contractAddress: dhtNode2.target,
            isLocal: false
        };

        await dhtNode1.storeAttributeRemote("humidity", remoteCoordinates);

        const [value, coordinates] = await dhtNode1.getAttributeValue("humidity");
        expect(value).to.equal(ethers.encodeBytes32String(""));
        expect(coordinates.chainId).to.equal(chain2.id);
        expect(coordinates.contractAddress).to.equal(dhtNode2.target);
    });

    it("Dovrebbe aggiungere un neighbor su un'altra chain", async function () {
        const neighborCoordinates = {
            chainId: chain2.id,
            contractAddress: dhtNode2.target,
            isLocal: false
        };

        await dhtNode1.addNeighbor(dhtNode2.target, ethers.encodeBytes32String("node2"), neighborCoordinates);

        const neighbors = await dhtNode1.getActiveNeighbors();
        expect(neighbors.length).to.equal(1);
        expect(neighbors[0].nodeAddress).to.equal(dhtNode2.target);
        expect(neighbors[0].coordinates.chainId).to.equal(chain2.id);
    });

    it("Dovrebbe gestire correttamente una richiesta cross-chain", async function () {
        // Aggiungiamo un neighbor su chain2
        const neighborCoordinates = {
            chainId: chain2.id,
            contractAddress: dhtNode2.target,
            isLocal: false
        };
        console.log("Neighbor coordinates:", neighborCoordinates);
        await dhtNode1.addNeighbor(dhtNode2.target, ethers.encodeBytes32String("node2"), neighborCoordinates);

        // // Registriamo un attributo su chain2
        // await network.provider.request({
        //     method: "hardhat_reset",
        //     params: [{
        //         forking: {
        //             jsonRpcUrl: "http://localhost:8545",
        //             blockNumber: 1,
        //         },
        //         chainId: chain2.id,
        //     }]
        // });

        await dhtNode2.connect(wallet2).storeAttributeLocal("pressure", ethers.encodeBytes32String("1013"));

        // // Torniamo alla chain1
        // await network.provider.request({
        //     method: "hardhat_reset",
        //     params: []
        // });

        // Testiamo la richiesta distribuita
        const [value, coordinates] = await dhtNode2.getDistributedAttribute("pressure");

        expect(coordinates.chainId).to.equal(chain2.id);
        expect(coordinates.contractAddress).to.equal(dhtNode2.target);

        // Nota: In un vero ambiente cross-chain, qui dovresti usare un bridge
        // o oracle per recuperare il valore effettivo dall'altra chain
        // Questo test verifica solo che le coordinate siano corrette
    });

    it("Dovrebbe preferire neighbors sulla stessa chain", async function () {
        // Aggiungiamo un neighbor su chain2
        const neighbor2Coordinates = {
            chainId: chain2.id,
            contractAddress: dhtNode2.target,
            isLocal: false
        };
        await dhtNode1.addNeighbor(dhtNode2.target, ethers.encodeBytes32String("node2"), neighbor2Coordinates);

        // Simuliamo un neighbor sulla stessa chain (chain1)
        const DHTNode = await ethers.getContractFactory("DecentralizedDHTNode");
        const dhtNodeLocal = await DHTNode.deploy();

        const neighborLocalCoordinates = {
            chainId: chain1.id,
            contractAddress: dhtNodeLocal.target,
            isLocal: true
        };
        await dhtNode1.addNeighbor(dhtNodeLocal.target, ethers.encodeBytes32String("nodeLocal"), neighborLocalCoordinates);

        // findClosestNode dovrebbe preferire il neighbor sulla stessa chain
        const closestNode = await dhtNode1.findClosestNode("anyAttribute");
        expect(closestNode).to.equal(dhtNodeLocal.target);
    });
});