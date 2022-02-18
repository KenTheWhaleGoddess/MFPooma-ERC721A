//"SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.8.7;
pragma experimental ABIEncoderV2;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

enum SaleState {
    NOSALE, PRESALE, MAINSALE
}

contract SimpleCollectible is ERC721A, Ownable {
    uint256 public tokenCounter;

    uint256 public _presalePrice = 10000000000000000;
    uint256 public _salePrice = 20000000000000000;

    uint256 public _presaleSupply = 100;
    uint256 public _totalSupply = 10000; 

    uint256 public _maxPerPresaleWallet = 6; //5

    string private _baseTokenURI;
    SaleState private _saleState; // 0 - No sale. 1 - Presale. 2 - Main Sale.

    // Faciliating the needed functionality for the presale
    mapping(address => bool) addressToPreSaleEntry;
    mapping(address => uint256) addressToMintedEntry;

    constructor () ERC721A ("DesignerPunk Kids","DP", 25, 5555)  {
        _saleState = SaleState.PRESALE;
        setBaseURI("https://mfproductions.mypinata.cloud/ipfs/QmeZ9dKXCFDJKJ63X9BQ7SRqp6Crf81xFxGVkkAwKkSSvo/");
    }

    function mintPresaleCollectibles(uint256 _count) public payable {
        require(_saleState == SaleState.PRESALE, "Sale is not yet open");
        require(addressToMintedEntry[msg.sender] + _count < _maxPerPresaleWallet, "Max reached per presale wallet");
        require(isWalletInPresale(msg.sender), "Wallet isnt in presale! The owner needs to addWalletToPresale.");
        require((_count + tokenCounter) <= _presaleSupply, "Ran out of NFTs for presale! Sry!");
        require(msg.value >= (_presalePrice * _count), "Ether value sent is too low");

        _safeMint(msg.sender, _count);
        tokenCounter += _count;
        addressToMintedEntry[msg.sender] += _count;
    }

    function mintCollectibles(uint256 _count) public payable {
        require(_saleState == SaleState.MAINSALE, "Sale is not yet open");
 
        require((_count + tokenCounter) <= _totalSupply, "Ran out of NFTs for sale! Sry!");
        require(msg.value >= (_salePrice * _count), "Ether value sent is not correct");

        _safeMint(msg.sender, _count);
         tokenCounter += _count;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(getBaseURI(), Strings.toString(tokenId), ".json"));
    }
    
    function setSaleState(SaleState saleState) public onlyOwner {
        _saleState = saleState;
    }

    function isWalletInPresale(address _address) public view returns (bool) {
        return addressToPreSaleEntry[_address];
    }
    function addWalletToPreSale(address _address) public onlyOwner {
        addressToPreSaleEntry[_address] = true;
    }
    
    function setMaxPerPresaleWallet(uint256 maxPerPresaleWallet) public onlyOwner {
        _maxPerPresaleWallet = maxPerPresaleWallet;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function getBaseURI() public view returns (string memory){
        return _baseTokenURI;
    }
    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}
