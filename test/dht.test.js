const { expect } = require("chai");
const { ethers } = require("hardhat");


const asciiArt = ` 
       (1)
      / | \\ 
     /  |  \\ 
   (2)-(3)-(4)
     \\  |  /
      \\ | /
       (5)
  `;


function printAsciiArt() {
  console.log(asciiArt);
}

describe("DHT Decentralized Nodes", function () {
  let dhtNode1, dhtNode2;
  const NODE1_ID = ethers.encodeBytes32String("node1")
  const NODE2_ID = ethers.encodeBytes32String("node2")
  const NODE3_ID = ethers.encodeBytes32String("node3")
  const NODE4_ID = ethers.encodeBytes32String("node4")
  const NODE5_ID = ethers.encodeBytes32String("node5")
  const RED = ethers.encodeBytes32String("red")
  const LEATHER = ethers.encodeBytes32String("leather")

  before(async function () {
    // Deployiamo due nodi DHT
    const DHTNode1 = await ethers.getContractFactory("DHTNode1");
    const DHTNode2 = await ethers.getContractFactory("DHTNode2");
    const DHTNode3 = await ethers.getContractFactory("DHTNode3");
    const DHTNode4 = await ethers.getContractFactory("DHTNode4");
    const DHTNode5 = await ethers.getContractFactory("DHTNode5");

    dhtNode1 = await DHTNode1.deploy();
    console.log("Node 1 deployed to:", dhtNode1.target);

    dhtNode2 = await DHTNode2.deploy();
    console.log("Node 2 deployed to:", dhtNode2.target);

    dhtNode3 = await DHTNode3.deploy();
    console.log("Node 3 deployed to:", dhtNode3.target);

    dhtNode4 = await DHTNode4.deploy();
    console.log("Node 4 deployed to:", dhtNode4.target);

    dhtNode5 = await DHTNode5.deploy();
    console.log("Node 5 deployed to:", dhtNode1.target);



    // Node 1 e Node 2 si collegano tra loro
    await dhtNode1.addNeighbor(dhtNode2.target, NODE2_ID);
    await dhtNode1.addNeighbor(dhtNode3.target, NODE3_ID);
    await dhtNode1.addNeighbor(dhtNode4.target, NODE4_ID);
    await dhtNode1.addNeighbor(dhtNode5.target, NODE5_ID);


    await dhtNode2.addNeighbor(dhtNode1.target, NODE2_ID);
    await dhtNode2.addNeighbor(dhtNode3.target, NODE3_ID);
    await dhtNode2.addNeighbor(dhtNode4.target, NODE4_ID);
    await dhtNode2.addNeighbor(dhtNode5.target, NODE5_ID);

    await dhtNode3.addNeighbor(dhtNode1.target, NODE2_ID);
    await dhtNode3.addNeighbor(dhtNode2.target, NODE2_ID);
    await dhtNode3.addNeighbor(dhtNode4.target, NODE4_ID);
    await dhtNode3.addNeighbor(dhtNode5.target, NODE5_ID);

    await dhtNode4.addNeighbor(dhtNode1.target, NODE2_ID);
    await dhtNode4.addNeighbor(dhtNode2.target, NODE2_ID);
    await dhtNode4.addNeighbor(dhtNode3.target, NODE4_ID);
    await dhtNode4.addNeighbor(dhtNode5.target, NODE5_ID);

    await dhtNode5.addNeighbor(dhtNode1.target, NODE2_ID);
    await dhtNode5.addNeighbor(dhtNode2.target, NODE2_ID);
    await dhtNode5.addNeighbor(dhtNode3.target, NODE4_ID);
    await dhtNode5.addNeighbor(dhtNode4.target, NODE5_ID);

    // Node 1 memorizza il materiale
    await dhtNode1.storeAttribute("material", LEATHER)

    // Node 2 memorizza il colore
    await dhtNode2.storeAttribute("color", RED);

    printAsciiArt();
  });

  it("Node 1 should get the local Attribute 'material' Leather", async function () {
    expect(await dhtNode1.getAttributeValue("material")).to.equal(LEATHER);
  });

  it("Node 2 should get the local attribute 'color' Red through the getDistributedAttribute function", async function () {
    expect(await dhtNode2.getDistributedAttribute("color")).to.equal(RED);
  });

  it("Node 2 shouldn't get the local attribute 'material' and raise an error 'Attribute not found'", async function () {
    await expect(
      dhtNode2.getAttributeValue("material")
    ).to.be.revertedWith("Attribute not found");
  });

  it("Node 1 should get the distributed attribute 'color' from Node 2", async function () {
    expect(await dhtNode1.getDistributedAttribute("color")).to.equal(RED);
  });

  it("Node 2 should get the distributed attribute 'material' from Node 1", async function () {
    expect(await dhtNode2.getDistributedAttribute("material")).to.equal(LEATHER);
  });

  it("Node 2 should get the distributed attribute 'protection' from Node 1", async function () {
    expect(await dhtNode2.getDistributedAttribute("protection")).to.equal(ethers.encodeBytes32String("100"));
  });
  it("Node 1 should get the distributed attribute 'protection' from Node 1", async function () {
    expect(await dhtNode1.getDistributedAttribute("protection")).to.equal(ethers.encodeBytes32String("100"));
  });

  it("Node 2 should get the distributed attribute 'name' from Node 2", async function () {
    expect(await dhtNode1.getDistributedAttribute("name")).to.equal(ethers.encodeBytes32String("NMT on DHTnode2"));
  });

  it("Node 3 should get the distributed attribute 'name' from Node 1", async function () {
    expect(await dhtNode3.getDistributedAttribute("material")).to.equal(LEATHER);
  });

  it("Node 4 should get the distributed attribute 'name' from Node 1", async function () {
    expect(await dhtNode4.getDistributedAttribute("material")).to.equal(LEATHER);
  });

  it("Node 1 should get the distributed attribute 'description' from Node 1", async function () {
    expect(await dhtNode5.getDistributedAttribute("description")).to.equal(ethers.encodeBytes32String("This is a dnmt description"));
  });
}); 
