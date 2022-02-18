//"SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

enum SaleState {
    NOSALE, PRESALE, MAINSALE
}

contract SimpleCollectible is ERC721A, Ownable, ReentrancyGuard {
    uint256 private tokenCounter;

    uint256 public presalePrice = 10000000000000000;
    uint256 public salePrice = 20000000000000000;

    uint256 private presaleSupply = 4;
    uint256 private maxSupply = 6; 

    uint256 private maxPerPresaleWallet = 6; //5
    uint256 private maxPerTx = 25;

    string private baseTokenURI;
    SaleState public saleState; // 0 - No sale. 1 - Presale. 2 - Main Sale.

    // Faciliating the needed functionality for the presale
    mapping(address => bool) addressToPreSaleEntry;
    mapping(address => uint256) addressToMintedEntry;
    mapping(address => bool) trustedProxy;

    constructor () ERC721A ("DesignerPunk Kids","DP", maxPerTx, maxSupply)  {
        saleState = SaleState.PRESALE;
        tokenCounter = 1;
        setBaseURI("https://mfproductions.mypinata.cloud/ipfs/QmeZ9dKXCFDJKJ63X9BQ7SRqp6Crf81xFxGVkkAwKkSSvo/");
    }

    function mintPresaleCollectibles(uint256 _count) public payable nonReentrant {
        require(saleState == SaleState.PRESALE, "Sale is not yet open");
        require(addressToMintedEntry[msg.sender] + _count < maxPerPresaleWallet, "Max reached per presale wallet");
        require(isWalletInPresale(msg.sender), "Wallet isnt in presale! The owner needs to addWalletToPresale.");
        require((_count + tokenCounter) <= presaleSupply, "Ran out of NFTs for presale! Sry!");
        require(msg.value >= (presalePrice * _count), "Ether value sent is too low");

        _safeMint(msg.sender, _count);
        tokenCounter += _count;
        addressToMintedEntry[msg.sender] += _count;
    }

    function mintCollectibles(uint256 _count) public payable nonReentrant {
        require(saleState == SaleState.MAINSALE, "Sale is not yet open");
 
        require((_count + tokenCounter) <= maxSupply, "Ran out of NFTs for sale! Sry!");
        require(msg.value >= (salePrice * _count), "Ether value sent is not correct");

        _safeMint(msg.sender, _count);
         tokenCounter += _count;
    }

    function mintForOwner(uint256 _count, address _user) public onlyOwner { 
        require((_count + tokenCounter) <= maxSupply, "Ran out of NFTs for sale! Sry!");

        _safeMint(_user, _count);
         tokenCounter += _count;
    }

    function getMaxSupply() public view returns (uint256) {
        return maxSupply - 1;
    }

    function getMaxPerTx() public view returns (uint256) {
        return maxPerTx;
    }
    function getPresaleSupply() public view returns (uint256) {
        return presaleSupply - 1;
    }
    function getMaxPerPresaleWallet() public view returns (uint256) {
        return maxPerPresaleWallet - 1;
    }
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(getBaseURI(), Strings.toString(tokenId), ".json"));
    }
    
    function setSaleState(SaleState _saleState) public onlyOwner {
        saleState = _saleState;
    }

    function isWalletInPresale(address _address) public view returns (bool) {
        return addressToPreSaleEntry[_address];
    }
    function addWalletToPreSale(address _address) public onlyOwner {
        addressToPreSaleEntry[_address] = true;
    }
    
    function setMaxPerPresaleWallet(uint256 _maxPerPresaleWallet) public onlyOwner {
        maxPerPresaleWallet = _maxPerPresaleWallet;
    }

    function flipProxyState(address _address) public onlyOwner {
        trustedProxy[_address] = !trustedProxy[_address];
    }
    function getProxyState(address _address) public view returns (bool) {
        return trustedProxy[_address];
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseTokenURI = uri;
    }

    function getBaseURI() public view returns (string memory){
        return baseTokenURI;
    }
    function withdrawAll() public payable onlyOwner nonReentrant {
        require(payable(msg.sender).send(address(this).balance));
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return trustedProxy[operator] || ERC721A.isApprovedForAll(owner, operator);
    }    
}
