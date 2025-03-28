const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("DHT Decentralized Nodes", function () {
  let dhtNode1, dhtNode2;
  // const assetId = "0x706970706f000000000000000000000000000000000000000000000000000000"
  const NODE1_ID =  ethers.encodeBytes32String("nodo1")
  const NODE2_ID =  ethers.encodeBytes32String("nodo2")
  const RED = ethers.encodeBytes32String("red")
  const LEATHER = ethers.encodeBytes32String("leather")
  
  before(async function () {
    // Deployiamo due nodi DHT
    const DHTNode1 = await ethers.getContractFactory("DHTNode1");
    const DHTNode2 = await ethers.getContractFactory("DHTNode2");

    dhtNode1 = await DHTNode1.deploy();
    console.log("Node 1 deployed to:", dhtNode1.target);

    dhtNode2 = await DHTNode2.deploy();
    console.log("Node 2 deployed to:", dhtNode2.target);

    // Nodo 1 memorizza il materiale
    await dhtNode1.storeAttribute("material", LEATHER)

    // Nodo 2 memorizza il colore
    await dhtNode2.storeAttribute( "color",  RED);

    // Nodo 1 e Nodo 2 si collegano tra loro
    await dhtNode1.addNeighbor(dhtNode2.target, NODE1_ID);
    await dhtNode2.addNeighbor(dhtNode1.target, NODE2_ID);
  });

  it("Nodo 1 deve restituire il materiale Leather", async function () {
    expect(await dhtNode1.getDistributedAttribute( "material")).to.equal(LEATHER);
  });

  it("Nodo 2 deve restituire il colore Red", async function () {
    expect(await dhtNode2.getDistributedAttribute( "color")).to.equal(RED);
  });

  it("Nodo 1 deve recuperare color da Nodo 2", async function () {
    expect(await dhtNode1.getDistributedAttribute( "color")).to.equal(RED);
  });

  it("Nodo 2 deve recuperare material da Nodo 1", async function () {
    expect(await dhtNode2.getDistributedAttribute( "material")).to.equal(LEATHER);
  });

  it("Nodo 2 deve recuperare protection da Nodo 1", async function () {
    expect(await dhtNode2.getDistributedAttribute( "protection")).to.equal(ethers.encodeBytes32String("100"));
  });

  it("Nodo 1 deve recuperare protection da Nodo 1", async function () {
    expect(await dhtNode1.getDistributedAttribute( "protection")).to.equal(ethers.encodeBytes32String("100"));
  });

  it("Nodo 2 deve recuperare name da Nodo 2", async function () {
    expect(await dhtNode1.getDistributedAttribute( "name")).to.equal(ethers.encodeBytes32String("NMT on DHTnode2"));
  });
});
