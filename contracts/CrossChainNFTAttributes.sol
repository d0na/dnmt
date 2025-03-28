// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

contract CrossChainNFTAttributes {

    struct Attribute {
        string key;      // Nome dell'attributo (es. "name", "image")
        string value;    // Valore dell'attributo (o hash se è su un'altra chain)
        string chainId;  // Blockchain in cui è memorizzato il valore
    }

    struct NFT {
        uint256 id;
        address owner;
        mapping(string => Attribute) attributes;
    }

    mapping(uint256 => NFT) public nfts;  // NFT ID -> NFT data
    uint256 public nftCount;               // Contatore degli NFT

    // Eventi per la creazione e modifica dell'NFT
    event NFTCreated(uint256 indexed nftId, address owner);
    event AttributeAdded(uint256 indexed nftId, string key, string value, string chainId);

    // Funzione per creare un nuovo NFT con attributi
    function createNFT(
        string memory name, 
        string memory image, 
        string memory attackPower, 
        string memory rarity
    ) public {
        nftCount++;
        NFT storage nft = nfts[nftCount];
        nft.id = nftCount;
        nft.owner = msg.sender;

        // Aggiungi gli attributi per l'NFT
        _addAttribute(nftCount, "name", name, "Ethereum");
        _addAttribute(nftCount, "image", image, "Ethereum");
        _addAttribute(nftCount, "attackPower", attackPower, "BinanceSmartChain");
        _addAttribute(nftCount, "rarity", rarity, "BinanceSmartChain");

        emit NFTCreated(nftCount, msg.sender);
    }

    // Funzione per aggiungere un attributo all'NFT
    function _addAttribute(
        uint256 nftId, 
        string memory key, 
        string memory value, 
        string memory chainId
    ) internal {
        NFT storage nft = nfts[nftId];
        nft.attributes[key] = Attribute(key, value, chainId);
        emit AttributeAdded(nftId, key, value, chainId);
    }

    // Funzione per ottenere un attributo dell'NFT
    function getAttribute(uint256 nftId, string memory key) public view returns (string memory value, string memory chainId) {
        NFT storage nft = nfts[nftId];
        Attribute storage attr = nft.attributes[key];
        return (attr.value, attr.chainId);
    }
}
