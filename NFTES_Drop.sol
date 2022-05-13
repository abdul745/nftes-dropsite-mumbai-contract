// SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;
import "./ERC1155_Upd.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract NFTES_Drop is ERC1155, Ownable {
     //NFT category
    // NFT Description & URL
    bytes data = "";
    uint256 totalNFTsMinted; //Total NFTs
    uint256 numOfCopies; //A user can mint only 1 NFT
    uint256 mintFees;

    //Initial Minting
    uint256 Diamond;
    uint256 Gold;
    uint256 Silver;

    //Max mint Slots
    uint256 maxDiamondCount=50;
    uint256 maxGoldCount=100;
    uint256 maxSilverCount=850;

    event isMinted(address indexed addr, string[]  ids);
    //owner-NFT-ID Mapping
    //Won NFTs w.r.t Addresses
    struct nft_Owner {
        uint256[] owned_Dropsite_NFTs;
    }

    mapping(address => nft_Owner) dropsite_NFT_Owner;

    //payments Mapping  
    mapping(address => uint256) deposits;
    modifier OnlyOwner() {
        require(_msgSender() == Owner, "Only NFT-ES Owner can Access");
        _;
    }

    //Pausing and activating the contract
    modifier contractIsNotPaused() {
        require(isPaused == false, "Dropsite is not Opened Yet.");
        _;
    }
    modifier mintingFeeIsSet() {
        require(mintFees != 0, "Owner Should set mint Fee First");
        _;
    }

    bool public isPaused = true;
    address payable public Owner;
    string public _name;
    string public _symbol;

    uint public constant DIAMOND_ID   = 0;
    uint public constant GOLD_ID  = 1;
    uint public constant SILVER_ID  = 2;

    mapping (uint=>string) tokenURI;
    event URI(string value, bytes indexed id);

    constructor()  ERC1155(""){
        _name = name();
        // _symbol = symbol;
        Owner = payable(msg.sender);

        totalNFTsMinted = 0; //Total NFTs Minted
        numOfCopies = 1; //A user can mint only 1 NFT in one call

        //Initially 0 NFTs have been minted
        Diamond = 0;
        Gold = 0;
        Silver = 0;
    }

    function name() public pure returns(string memory){
    return "NFT-ES Drop";
   }

    function symbol() public pure returns(string memory){
        return "NED";
    }
    function isAdmin() public view returns (bool){
        if(msg.sender==Owner) return true;
        else return false;
    }
   
    function setURI(uint _id, string memory _uri) private onlyOwner {
    tokenURI[_id] = _uri;
    emit URI(_uri, _id);
  }

  function getURI(uint _id) public  view returns (string memory) {
    return tokenURI[_id];
  }

    function changeOwner(address newOwnerAddr)
        public
        OnlyOwner
        contractIsNotPaused
    {
        Owner = payable(newOwnerAddr);
    }

    //Check NFTs issued to an address
    function returnNftsOwner(address addr)
        public
        view
        contractIsNotPaused
        returns (uint256[] memory)
    {
        return dropsite_NFT_Owner[addr].owned_Dropsite_NFTs;
    }

    //To Check No of issued NFTs Category Wise
    function checkMintedCategoryWise()
        public
        view
        OnlyOwner
        contractIsNotPaused
        returns (
            uint,
            uint,
            uint
        )
    {
        return (Diamond, Gold, Silver);
    }

    //To set Standard NFT minting Fee
    function setMintFee(uint _mintFee) public OnlyOwner  {
        mintFees = _mintFee;
    }

    //Get current Mint Fee
    function getMintFee()
        public
        view
        returns (uint256)
    {
        return mintFees;
    }

    //To Check total Minted NFTs
    function checkTotalMinted() public view returns (uint256) {
        return totalNFTsMinted;
    }

    function stopDropsite() public OnlyOwner {
        require(isPaused == false, "Dropsite is already Stopped");
        isPaused = true;
    }

    function openDropsite() public OnlyOwner {
        require(isPaused == true, "Dropsite is already Running");
        isPaused = false;
    }

    //To WithDraw All Ammount from Contract to Owners Address or any other Address
    function withDraw(address payable to, uint amount) public  OnlyOwner {
        uint256 Balance = address(this).balance;
        require(amount <= Balance, "Error! Not Enough Balance");
        to.transfer(amount);
    }

    //To Check Contract Balance in Wei
    function contractBalance() public view OnlyOwner returns (uint256) {
        return address(this).balance;
    }


    //Random Number to Select an item from nums Array(Probabilities)
    //Will return an index b/w 0-20
    function random() internal view returns (uint256) {
        // Returns 0-20
        //To Achieve maximum level of randomization!
        uint256 randomnumber = uint256(
            keccak256(
                abi.encodePacked(
                    ((block.timestamp) +
                        totalNFTsMinted +
                        Silver +
                        Gold +
                        Diamond),
                    msg.sender,
                    Owner
                )
            )
        );
        return randomnumber;
    }
    //To check and update conditions wrt nftId
    function updateConditions(uint256 index)
        internal
        contractIsNotPaused
        returns (uint256)
    {
        uint nftId;
        if((index) % 20 == 1 && Diamond < maxDiamondCount){
            Diamond++;
            data = bytes(string(
                abi.encodePacked("Diamond_", Strings.toString(Diamond))
            ));
            return nftId=0;
            // if nftID is 0 and Diamond is more than 50, it will go there in Gold Category
        } else if ((index) % 20 <= 3 && Gold < maxGoldCount) {
            Gold++;
            data = bytes(string(abi.encodePacked("Gold_", Strings.toString(Gold))));
            return nftId=1;
            // if any of the above conditions are filled it will mint silver if enough silver available
        } else if ((index) % 20 > 3 && Silver < maxSilverCount) {
            Silver++;
            data = bytes(string(
                abi.encodePacked("Silver_", Strings.toString(Silver))
            ));
            return nftId=2;
        } else {

            //if nft ID is either 1 or 2, but Slots in Gold or Diamond are remaining,
            //First Gold category will be filled then Diamond
            if (Gold < maxGoldCount) {
                nftId = 1;
                Gold++;
                data = bytes(string(
                    abi.encodePacked("Gold_", Strings.toString(Gold))
                ));
                return nftId;
            } else {
                nftId = 0;
                Diamond++;
                data = bytes(string(
                    abi.encodePacked("Diamond_", Strings.toString(Diamond))
                ));
                return nftId;
            }
        }
    }

    function randomMinting(address user_addr)
        internal
        contractIsNotPaused
        returns (uint256, bytes memory)
    {
        // nftId = random(); // we're assuming that random() returns only 0,1,2
        uint256 index = random();
        uint256 nftId = updateConditions(index);
        _mint(user_addr, nftId, numOfCopies, data);
        totalNFTsMinted++;
        dropsite_NFT_Owner[user_addr].owned_Dropsite_NFTs.push(nftId);
        if(nftId==0)
            setURI(nftId, "ipfs://QmNV7yv64ec5im7JgkL9GZyBC7wx7ZBdDLChAjfBsZ8x6Y/DiamondMetadata.json");
        else if(nftId==1)
            setURI(nftId, "ipfs://QmNV7yv64ec5im7JgkL9GZyBC7wx7ZBdDLChAjfBsZ8x6Y/GoldMetadata.json");
        else if(nftId==2)
            setURI(nftId, "ipfs://QmNV7yv64ec5im7JgkL9GZyBC7wx7ZBdDLChAjfBsZ8x6Y/SilverMetadata.json");
        
        return (nftId, data);
    }

    //Random minting after Fiat Payments
    function fiatRandomMint(address user_addr, uint256 noOfMints)
        public
        OnlyOwner
        contractIsNotPaused
        mintingFeeIsSet
        returns (string[] memory)
    {
        require(noOfMints < 4 && noOfMints > 0, "You can mint 1-3 NFTs");
        require(totalNFTsMinted < 1000, "Max Minting Limit reached");
        require(mintFees != 0, "Mint Fee Not Set");
        uint returnedNftID;
        bytes memory returnedNftData;
        string[] memory randomMintedNfts = new string[](3);
        for (uint256 i = 0; i < noOfMints; i++) {
            (returnedNftID, returnedNftData) = randomMinting(user_addr);
              randomMintedNfts[i]= 
                    string(abi.encodePacked(Strings.toString(returnedNftID),"_", returnedNftData));
        }
        
        emit isMinted(user_addr, randomMintedNfts);
        return randomMintedNfts;
    }

    //MATIC Amount will be deposited
    function depositAmount(address payee, uint256 amountToDeposit) internal {
        deposits[payee] += amountToDeposit;
    }

    function checkTokenURIs(uint nft_id) internal {

    }

    //Random minting after Crypto Payments
    function cryptoRandomMint(address user_addr, uint256 noOfMints)
        public
        payable
        contractIsNotPaused
        mintingFeeIsSet
        returns (string[] memory)
    {
        require(noOfMints < 4 && noOfMints > 0, "You can mint 1-3 NFTs");
        require(totalNFTsMinted < 1000, "Max Minting Limit reached");
        require(mintFees != 0, "Mint Fee Not Set");
        require(msg.value == mintFees * noOfMints, "Not Enough Balance");
        uint returnedNftID;
        bytes memory returnedNftData;
        string[] memory randomMintedNfts = new string[](3);
        for (uint256 i = 0; i < noOfMints; ++i) {
          (returnedNftID, returnedNftData) = randomMinting(user_addr);
              randomMintedNfts[i]= 
                    string(abi.encodePacked(Strings.toString(returnedNftID),"_", returnedNftData));
        }
        depositAmount(_msgSender(), msg.value);
        emit isMinted(user_addr, randomMintedNfts);
        return randomMintedNfts;
    }

}
