// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

abstract contract PriceOFMATICTOUSD {
    AggregatorV3Interface priceFeed;
    // 18 decimals
    uint256 requiredPriceInUsd = 10 * 1e18;

    constructor() {
        priceFeed = AggregatorV3Interface(0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada);
    }

    // returns amount of in 1e18) ;
    function getconversionRate(uint256 Amount) public view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();

        // returned price is 8 decimals, convert to 18 decimal
        uint256 UsdPrice = uint256(answer * 1e10);

        // 36 decimals / 18 decimals = 18 decimals
        uint256 requiredpricenusd = (Amount * UsdPrice) / 1e18;
        return requiredpricenusd;
    }
}

contract HomeWorks is ERC721Enumerable, PriceOFMATICTOUSD, Ownable {
    using Strings for uint256;

    string baseURI;
    string public baseExtension = ".json";
    bool public paused = false;
    bool public revealed = false;
    string public notRevealedUri;
    uint256 cost;
    uint256 maxSupply;
    uint256 maxMintAmount;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _initialPrice,
        uint256 _initialSupply,
        uint256 maxntno,
        string memory _initBaseURI,
        string memory _initNotRevealedUri
    ) ERC721(_name, _symbol) {
        setPrice(_initialPrice);
        setmaxMintAmount(maxtominT);
        setSupply(_initialSupply);
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // public
    function mint(uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();
        require(!paused);
        //require( getconversionRate(msg.value) >= cost * _mintAmount, "Insufficient ETH" );
        require(_mintAmount > 0 && _mintAmount <= maxMintAmount);

        require(supply + _mintAmount <= maxSupply);

        if (msg.sender != owner()) {
            require(getconversionRate(msg.value) >= cost * _mintAmount, "not enough matic");
        }
        if (msg.sender == owner()) {
            require(getconversionRate(msg.value) >= cost * _mintAmount, "not enough matic");
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
                : "";
    }

    //only owner
    function reveal() public onlyOwner {
        revealed = true;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        cost = _newPrice;
    }

    function setSupply(uint256 _newSupply) public onlyOwner {
        maxSupply = _newSupply;
    }

    function getSupply() public view returns (uint256) {
        return maxSupply;
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{ value: address(this).balance }("");
        require(os);
    }
}
