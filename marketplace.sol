// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//@ts-ignore
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract NFTMarketplace is ERC721URIStorage {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    uint256 public mintFee = 90000000000000000;

    mapping(address => bool) private adminList;
    
    Counters.Counter private _tokenIds;
    Counters.Counter private _itemsSold;
    Counters.Counter private _items;
    bool public onlyAdmin = true;
    uint256 public maxLimit = 5;
    address payable owner;

    mapping(uint256 => MarketItem) private idToMarketItem;
    
    modifier onlyOwner{
        require(msg.sender==owner,"Only owner is allowed for this operation");
        _;
    }

    struct MarketItem {
      uint256 itemId;
      uint256 tokenId;
      address nftContract;  
      address payable seller;
      address payable owner;
      uint256 price;
      bool sold;
    }

    event MarketItemCreated (
      uint256 itemId,
      uint256 indexed tokenId,
      address nftContract,
      address seller,
      address owner,
      uint256 price,
      bool sold
    );

    constructor() ERC721("ABC", "abc") {
      owner = payable(msg.sender);
      adminList[msg.sender] = true;
    }

    function calculateFee(uint256 _num) internal pure returns (uint256){
        uint256 onePercentofTokens = _num.mul(100).div(100 * 10 ** uint256(2));
        uint256 twoPercentOfTokens = onePercentofTokens.mul(2);
        uint256 halfPercentOfTokens = onePercentofTokens.div(2);
        return twoPercentOfTokens + halfPercentOfTokens;
    }
 
    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }


    function createMarketItemOutside(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) public payable {
        require(IERC721(nftContract).isApprovedForAll(msg.sender, address(this)), "Market deosn't have approval of token");
        if(adminList[msg.sender] != true)
        { 
          require(msg.value>=(calculateFee(price)),"Not enough fee sent for listing");
        }
        _items.increment();
        uint256 itemId = _items.current();
        idToMarketItem[itemId] =  MarketItem(
            itemId,
            tokenId,
            nftContract,
            payable(msg.sender),
            payable(address(this)),
            price,
            false
        );
        IERC721(nftContract).transferFrom(msg.sender, address(this),tokenId);
        emit MarketItemCreated(
            itemId,
            tokenId,
            nftContract,
            msg.sender,
            address(this),
            price,
            false
        );
        
    }


   /* Mints a token and lists it in the marketplace */
    function createTokenBatch(string[] memory tokenURI, uint256[] memory price,uint256 amount) public payable returns (uint256[] memory) {
      require(amount<=maxLimit,"Batch mint limit exceeded");
      if(onlyAdmin==true){
        require(adminList[msg.sender] == true,"Only admins can mint");
      }
      require(amount == tokenURI.length,"Amount of tokens and uri should be same");

      if(adminList[msg.sender] != true)
      { 
        uint256 fees = 0;
        for(uint256 i =0; i<amount;i++){
           fees = fees + calculateFee(price[i]);
        }
        fees=fees+(mintFee*amount);

        require(msg.value>=fees,"Not enough fee sent for listing");
      }

      require(amount == tokenURI.length,"Amount of tokens and uri should be same");
      uint256[] memory tokenIds = new uint256[](amount);
      for(uint256 i = 0; i<amount;i++){
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI[i]);
        uint256 newItemId = createMarketItem(newTokenId, price[i]);
        tokenIds[i] = newItemId;
      }
      return tokenIds;
    }

    /* Mints a token and lists it in the marketplace */
    function createToken(string memory tokenURI, uint256 price) public payable returns (uint) {
      if(onlyAdmin==true){
        require(adminList[msg.sender] == true,"Only admins can mint");
      }
      if(adminList[msg.sender] != true)
      { 
        require(msg.value>=(calculateFee(price)+mintFee),"Not enough fee sent for listing");
      }
      _tokenIds.increment();
      uint256 newTokenId = _tokenIds.current();
      _mint(msg.sender, newTokenId);
      _setTokenURI(newTokenId, tokenURI);
      uint256 newItemId = createMarketItem(newTokenId, price);
      return newItemId;
    }

    function createMarketItem(
      uint256 tokenId,
      uint256 price
    ) private returns(uint256){
      require(price > 0, "Price must be at least 1 wei");
      
      _items.increment();
      uint256 itemId = _items.current();
      idToMarketItem[itemId] =  MarketItem(
        itemId,
        tokenId,
        address(this),
        payable(msg.sender),
        payable(address(this)),
        price,
        false
      );
      _transfer(msg.sender, address(this), tokenId);
      emit MarketItemCreated(
        itemId,
        tokenId,
        address(this),
        msg.sender,
        address(this),
        price,
        false
      );
      return itemId;
    }

    /* allows someone to resell a token they have purchased */
    function resellToken(uint256 itemId, uint256 price) public payable {
      require(idToMarketItem[itemId].owner == msg.sender, "Only item owner can perform this operation");
       if(adminList[msg.sender] != true)
      {
          require(msg.value>=calculateFee(price),"Not enough fee sent for listing");
      }
      idToMarketItem[itemId].sold = false;
      idToMarketItem[itemId].price = price;
      idToMarketItem[itemId].seller = payable(msg.sender);
      idToMarketItem[itemId].owner = payable(address(this));
      _itemsSold.decrement();
      if(idToMarketItem[itemId].nftContract!=address(this)){
        IERC721(idToMarketItem[itemId].nftContract).transferFrom(msg.sender, address(this),idToMarketItem[itemId].tokenId);
      }
      else{
        _transfer(msg.sender, address(this), idToMarketItem[itemId].tokenId);

      }
    }

    /* Creates the sale of a marketplace item */
    /* Transfers ownership of the item, as well as funds between parties */
    function createMarketSale(
      uint256 itemId
      ) public payable {
      uint price = idToMarketItem[itemId].price;
      address seller = idToMarketItem[itemId].seller;
      require(msg.value >= price, "Please submit the asking price in order to complete the purchase");
      idToMarketItem[itemId].owner = payable(msg.sender);
      idToMarketItem[itemId].sold = true;
      idToMarketItem[itemId].seller = payable(address(0));
      _itemsSold.increment();
      if(idToMarketItem[itemId].nftContract!=address(this)){
        IERC721(idToMarketItem[itemId].nftContract).transferFrom(address(this), msg.sender, idToMarketItem[itemId].tokenId);
      }
      else{
        _transfer(address(this), msg.sender, idToMarketItem[itemId].tokenId);
      }
      
      payable(seller).transfer(msg.value);
    }

    /* Returns all unsold market items */
    function fetchMarketItems() public view returns (MarketItem[] memory) {
      uint itemCount = _items.current();
      uint unsoldItemCount = _items.current() - _itemsSold.current();
      uint currentIndex = 0;

      MarketItem[] memory items = new MarketItem[](unsoldItemCount);
      for (uint i = 0; i < itemCount; i++) {
        if (idToMarketItem[i + 1].owner == address(this)) {
          uint currentId = i + 1;
          MarketItem storage currentItem = idToMarketItem[currentId];
          items[currentIndex] = currentItem;
          currentIndex += 1;
        }
      }
      return items;
    }

    /* Returns only items that a user has purchased */
    function fetchMyNFTs() public view returns (MarketItem[] memory) {
      uint totalItemCount = _items.current();
      uint itemCount = 0;
      uint currentIndex = 0;

      for (uint i = 0; i < totalItemCount; i++) {
        if (idToMarketItem[i + 1].owner == msg.sender) {
          itemCount += 1;
        }
      }

      MarketItem[] memory items = new MarketItem[](itemCount);
      for (uint i = 0; i < totalItemCount; i++) {
        if (idToMarketItem[i + 1].owner == msg.sender) {
          uint currentId = i + 1;
          MarketItem storage currentItem = idToMarketItem[currentId];
          items[currentIndex] = currentItem;
          currentIndex += 1;
        }
      }
      return items;
    }

    /* Returns only items a user has listed */
    function fetchItemsListed() public view returns (MarketItem[] memory) {
      uint totalItemCount = _items.current();
      uint itemCount = 0;
      uint currentIndex = 0;

      for (uint i = 0; i < totalItemCount; i++) {
        if (idToMarketItem[i + 1].seller == msg.sender) {
          itemCount += 1;
        }
      }

      MarketItem[] memory items = new MarketItem[](itemCount);
      for (uint i = 0; i < totalItemCount; i++) {
        if (idToMarketItem[i + 1].seller == msg.sender) {
          uint currentId = i + 1;
          MarketItem storage currentItem = idToMarketItem[currentId];
          items[currentIndex] = currentItem;
          currentIndex += 1;
        }
      }
      return items;
    }

    function addUserAllowList(address _user) public onlyOwner {
        adminList[_user] = true;
    }
    
    function removeUserAllowList(address _user) public onlyOwner {
        adminList[_user] = false;       
    }

    function changeOwner(address payable _owner) public onlyOwner{
        owner = _owner;
    }
    
    function withdraw() public onlyOwner {
        (bool os, ) = payable(owner).call{value: address(this).balance}("");
        require(os);
    }

    function setFee(uint256 _cost) public onlyOwner {
        mintFee = _cost;
    }

    function setOnlyAdmin(bool _onlyAdmin) public onlyOwner {
      onlyAdmin=_onlyAdmin;
    }

    function setMaxLimit(uint256 _maxLimit) public onlyOwner {
      maxLimit=_maxLimit;
    }
}