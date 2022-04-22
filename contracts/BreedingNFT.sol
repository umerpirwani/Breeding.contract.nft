//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BreedingNFT is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    address busdAddress = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address tbusdAddress = 0xB0D0eDB26B7728b97Ef6726dAc6FB7a43d6043E1;

    IERC20 busd = IERC20(busdAddress);
    IERC20 tbusd = IERC20(tbusdAddress);

    address public creatorAddress = 0xA0B073bE8799A742407aB04eC02b2BfD860a1B71;

    event NewBaseURI(address base_uri);

    // Optional mapping for owner, tokenId, tokenURI
    struct NFT {
        uint256 tokenId;
        string tokenURI;
        uint256 price;
        uint256 pi;
        bool sale;
    }
    mapping(uint256 => NFT) public NFTs;

    constructor() ERC721("BreedingNFT", "BNT") {}

    function mintNFT(
        address recipient,
        string memory tokenURI,
        uint256 price,
        uint256 pi
    ) public onlyOwner {
        _tokenIds.increment();

        tbusd.transferFrom(msg.sender, address(this), price * 10**18);
        uint256 newTokenId = _tokenIds.current();
        _safeMint(recipient, newTokenId);

        NFTs[newTokenId] = NFT({
            tokenId: newTokenId,
            tokenURI: tokenURI,
            price: price,
            pi: pi,
            sale: true
        });
    }

    // Utils
    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensIds = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensIds[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensIds;
    }

    function buyNFT(uint256 tokenId, uint256 price) public {
        address _owner = ownerOf(tokenId);
        require(_owner != msg.sender, "It is still your NFT");
        require(
            tbusd.balanceOf(msg.sender) > price * 10**18,
            "Insuficient funds!"
        );
        _transfer(_owner, msg.sender, tokenId);
        // to davide : royalty
        tbusd.transferFrom(
            msg.sender,
            creatorAddress,
            ((price * 3) / 100) * 10**18
        );
        // Sale status : false
        NFTs[tokenId].sale = false;
        // to buyer : price - royalt
        tbusd.transferFrom(msg.sender, _owner, ((price * 97) / 100) * 10**18);
    }

    function resellNFT(uint256 tokenId) public {
        NFTs[tokenId].sale = true;
        // change the price to add P.I

        NFTs[tokenId].price =
            NFTs[tokenId].price +
            (NFTs[tokenId].price * NFTs[tokenId].pi) /
            100;
    }

    // GETTER
    function _totalSupply() internal view returns (uint256) {
        return _tokenIds.current();
    }

    function totalMint() public view returns (uint256) {
        return _totalSupply();
    }

    function getNFT(uint256 _tokenId)
        external
        view
        returns (
            bool,
            string memory,
            uint256
        )
    {
        return (
            NFTs[_tokenId].sale,
            NFTs[_tokenId].tokenURI,
            NFTs[_tokenId].price
        );
    }

    function withdrawAll() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _widthdraw(creatorAddress, address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }
}
