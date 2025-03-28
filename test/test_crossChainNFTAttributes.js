
const { expect } = require("chai");

describe("CrossChainNFTAttributes Contract", function () {
  let nftContract;
  let owner;

  beforeEach(async function () {
    const [deployer] = await ethers.getSigners();
    owner = deployer;

    const NFTContract = await ethers.getContractFactory("CrossChainNFTAttributes");
    nftContract = await NFTContract.deploy();
  });

  it("should create an NFT with 4 attributes", async function () {
    const name = "Drago Rosso";
    const image = "0xabc123...";
    const attackPower = "100";
    const rarity = "Leggendario";

    await nftContract.createNFT(name, image, attackPower, rarity);

    const nftId = 1;

    // Check name and image on Ethereum chain
    const [nameValue, nameChain] = await nftContract.getAttribute(nftId, "name");
    expect(nameValue).to.equal(name);
    expect(nameChain).to.equal("Ethereum");

    const [imageValue, imageChain] = await nftContract.getAttribute(nftId, "image");
    expect(imageValue).to.equal(image);
    expect(imageChain).to.equal("Ethereum");

    // Check attackPower and rarity on Binance Smart Chain
    const [attackPowerValue, attackPowerChain] = await nftContract.getAttribute(nftId, "attackPower");
    expect(attackPowerValue).to.equal(attackPower);
    expect(attackPowerChain).to.equal("BinanceSmartChain");

    const [rarityValue, rarityChain] = await nftContract.getAttribute(nftId, "rarity");
    expect(rarityValue).to.equal(rarity);
    expect(rarityChain).to.equal("BinanceSmartChain");
  });

  it("should emit the correct events when an NFT is created", async function () {
    const name = "Drago Rosso";
    const image = "0xabc123...";
    const attackPower = "100";
    const rarity = "Leggendario";

    await expect(nftContract.createNFT(name, image, attackPower, rarity))
      .to.emit(nftContract, "NFTCreated")
      .withArgs(1, owner.address);

    await expect(nftContract.createNFT(name, image, attackPower, rarity))
      .to.emit(nftContract, "AttributeAdded")
      .withArgs(1, "name", name, "Ethereum");

    await expect(nftContract.createNFT(name, image, attackPower, rarity))
      .to.emit(nftContract, "AttributeAdded")
      .withArgs(1, "image", image, "Ethereum");

    await expect(nftContract.createNFT(name, image, attackPower, rarity))
      .to.emit(nftContract, "AttributeAdded")
      .withArgs(1, "attackPower", attackPower, "BinanceSmartChain");

    await expect(nftContract.createNFT(name, image, attackPower, rarity))
      .to.emit(nftContract, "AttributeAdded")
      .withArgs(1, "rarity", rarity, "BinanceSmartChain");
  });
});
