//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NFTMarketplace is ERC721URIStorage {

    address payable owner; 
    // counters from utils 
    using Counters for Counters.Counter; 
    Counters.Counter private _tokenIds;
    Counters.Counter private _itemSold; 
    //defining listing fee 
    uint256 listPrice = 0.01 ether;
    //constructor
    constructor() ERC721("NFTMarketplace", "NFTM") {
        owner = payable(msg.sender);
    }

    //listed single NFT with its dependencies as owner, price, etc.
    struct ListedToken {
        uint256 tokenId;
        address payable owner;
        address payable seller;
        uint256 price;
        bool currentlyListed;
    }

    //mapping of listed nfts
    mapping(uint256 => ListedToken) private idToListedToken;

// help function //

    // F: UPDATE PRICE OF NFT //
    function updateListPrice(uint256 _listPrice) public payable {
        //only owner can change listing price
        require(owner == msg.sender, "Only owner can update lising price");
        listPrice = _listPrice;
    }

    //F: GET LISTING PRICE OF NFT //
    function getListPrice() public view returns (uint256) {
        return listPrice;
    }

    // F: get latest listed nft //
    function getLatestIdToListedToken() public view returns (ListedToken memory) {
        uint256 currentTokenId = _tokenIds.current();
        return idToListedToken[currentTokenId];
    }

    // F: for retrieving nft data for front //
    function getListedForTokenId(uint256 tokenId) public view returns(ListedToken memory) {
        return idToListedToken[tokenId];
    }

    // F: get current token id //
    function getCurrentToken() public view returns(uint256) {
        return _tokenIds.current();
    }

// main NFT marketplace functions //
// CREATING TOKEN FUNCTIONS//

    // F: create NFT token //
    function createToken(string memory tokenURI, uint256 price) public payable returns(uint) {
        require(msg.value == listPrice, "Send enough ETH to list");
        require(price > 0, "Make sure that price is bigger than 0");
        //safemint function
        _tokenIds.increment();
        uint256 currentTokenId = _tokenIds.current();
        _safeMint(msg.sender, currentTokenId);
        //set Token URI
        _setTokenURI(currentTokenId, tokenURI);
        //
        createListedToken(currentTokenId, price);
        return currentTokenId;
    }

    // F: create listed token, private, not called on front, ListedToken is struct//
    function createListedToken(uint256 tokenId, uint256 price) private {
        idToListedToken[tokenId] = ListedToken(
            tokenId,
            payable(address(this)),
            payable(msg.sender),
            price,
            true
        );
        //transfer ownership of that nft; transfer(from, where, what)
        _transfer(msg.sender, address(this), tokenId);
    }
//END CREATING TOKEN FUNCTIONS//

    // F: for storing and fetching all listed NFTs
    function getAllNFTs() public view returns(ListedToken[] memory) {
        uint nftCount = _tokenIds.current();
        //creating tokens struct for listed nfts
        ListedToken[] memory tokens = new ListedToken[](nftCount);

        uint currentIndex = 0;

        for(uint i=0; i<nftCount; i++) {
            uint currentId = i+1;
            //creating item for each listed nfts
            ListedToken storage currentItem = idToListedToken[currentId];
            tokens[currentIndex] = currentItem;
            currentIndex += 1;
        }
        //return struct tokens (listed nfts)
        return tokens;
    }

        // F: for storing and fetching all user NFTs
        function getMyNfts() public view returns(ListedToken[] memory) {
            uint totalItemCount = _tokenIds.current();
            uint itemCount = 0; 
            uint currentIndex = 0;

            //important to get a count of relevant user NFTs before making array from them
            for(uint i=0; i < totalItemCount; i++) {
                if(idToListedToken[i+1].owner == msg.sender || idToListedToken[i+1].seller == msg.sender) {
                    itemCount += 1;
                }
            } 

            //once there's count of user relevant NFTs create an array and store all NFTS in it
            ListedToken[] memory items = new ListedToken[](itemCount);
            for(uint i = 0; i < totalItemCount; i++) {
                if(idToListedToken[i+1].owner == msg.sender || idToListedToken[i+1].seller == msg.sender) {
                    uint currentId = i + 1;
                    ListedToken storage currentItem = idToListedToken[currentId];
                    items[currentIndex] = currentItem;
                    currentIndex += 1;
                }
              }
              //returning array with listed NFTs of user
            return items;
            }

    // F: EXECUTE SALE OF LISTED NFT
    function executeSale(uint256 tokenId) public payable {
        //set price 
        uint price = idToListedToken[tokenId].price;
        require(msg.value == price, "Please submit the asking price to purchase NFT");
        // set seller address
        address seller = idToListedToken[tokenId].seller;
        //set listed to true
        idToListedToken[tokenId].currentlyListed = true;
        //
        idToListedToken[tokenId].seller = payable(msg.sender);
        //increment sold items
        _itemSold.increment();

        //transfer the token
        _transfer(address(this), msg.sender, tokenId);
        // msg sender must approve contract to send nft to seller
        approve(address(this), tokenId);    
        //transfer money to seller
        payable(owner).transfer(listPrice);
        payable(seller).transfer(msg.value);

    }


}