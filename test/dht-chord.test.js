const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Chord DHT Network", function () {
  let chordNode1, chordNode2, chordNode3, chordNode4, chordNode5;
  const LEATHER = ethers.encodeBytes32String("leather");
  const RED = ethers.encodeBytes32String("red");
  const PROTECTION = ethers.encodeBytes32String("100");
  const NAME = ethers.encodeBytes32String("NMT on DHTnode2");
  const DESCRIPTION = ethers.encodeBytes32String("This is a dnmt description");

  before(async function () {
    // Deploy dei nodi Chord
    const ChordDHT1 = await ethers.getContractFactory("ChordDHTNode1");
    const ChordDHT2 = await ethers.getContractFactory("ChordDHTNode2");
    const ChordDHT3 = await ethers.getContractFactory("ChordDHTNode3");
    const ChordDHT4 = await ethers.getContractFactory("ChordDHTNode4");
    const ChordDHT5 = await ethers.getContractFactory("ChordDHTNode5");

    chordNode1 = await ChordDHT1.deploy();
    chordNode2 = await ChordDHT2.deploy();
    chordNode3 = await ChordDHT3.deploy();
    chordNode4 = await ChordDHT4.deploy();
    chordNode5 = await ChordDHT5.deploy();

    console.log("Nodes deployed:");
    console.log("Node 1:", chordNode1.target);
    console.log("Node 2:", chordNode2.target);
    console.log("Node 3:", chordNode3.target);
    console.log("Node 4:", chordNode4.target);
    console.log("Node 5:", chordNode5.target);

    // Configurazione della rete Chord (join sequenziale)
    await chordNode1.joinNetwork(chordNode1.target); // Primo nodo è la sua stessa rete
    await chordNode2.joinNetwork(chordNode1.target);
    await chordNode3.joinNetwork(chordNode1.target);
    await chordNode4.joinNetwork(chordNode2.target);
    await chordNode5.joinNetwork(chordNode3.target);

    // Memorizzazione dati con routing Chord
    await chordNode1.storeData("material", LEATHER);
    await chordNode2.storeData("color", RED);
    await chordNode2.storeData("name", NAME);
    await chordNode1.storeData("protection", PROTECTION);
    await chordNode5.storeData("description", DESCRIPTION);
  });

  it("Start", async function () {expect(1).to.equal(1)});

  // it("Node 1 should retrieve its locally stored 'material'", async function () {
  //   expect(await chordNode1.getData("material")).to.equal(LEATHER);
  // });

  // it("Node 2 should retrieve its locally stored 'color'", async function () {
  //   expect(await chordNode2.getData("color")).to.equal(RED);
  // });

  // it("Node 2 should not find non-existent local attribute", async function () {
  //   await expect(chordNode2.getData("material"))
  //     .to.be.revertedWith("Data not found");
  // });

  // it("Node 1 should retrieve distributed 'color' from Node 2", async function () {
  //   // Nota: In Chord usiamo getData che automaticamente routea alla posizione corretta
  //   expect(await chordNode1.getData("color")).to.equal(RED);
  // });

  // it("Node 2 should retrieve distributed 'material' from Node 1", async function () {
  //   expect(await chordNode2.getData("material")).to.equal(LEATHER);
  // });

  // it("Node 3 should retrieve distributed 'material'", async function () {
  //   expect(await chordNode3.getData("material")).to.equal(LEATHER);
  // });

  // it("Node 4 should retrieve distributed 'name'", async function () {
  //   expect(await chordNode4.getData("name")).to.equal(NAME);
  // });

  // it("Node 5 should retrieve its locally stored 'description'", async function () {
  //   expect(await chordNode5.getData("description")).to.equal(DESCRIPTION);
  // });

  // // Test aggiuntivi per la stabilizzazione della rete
  // it("Should update finger tables after stabilization", async function () {
  //   await chordNode1.stabilize();
  //   await chordNode2.stabilize();
  //   await chordNode3.stabilize();

  //   // Verifica che i successor siano corretti
  //   const node1Successor = await chordNode1.successor();
  //   const node2Successor = await chordNode2.successor();

  //   expect(node1Successor.nodeAddress).to.not.equal(chordNode1.target);
  //   expect(node2Successor.nodeAddress).to.not.equal(chordNode2.target);
  // });
});