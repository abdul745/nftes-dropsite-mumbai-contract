// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/ERC1155.sol)
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
import "./ERC1155.sol"; 
import "./ERC1155Burnable.sol";
import "./NFTES1155Royalties.sol";
contract NFTES1155 is ERC1155, ERC1155Burnable, NFTES1155Royalties { 

    mapping (uint=>string)TokenURI;
    
    // NFT ID to Price
    mapping (address=>mapping(uint=>uint)) NFT_Price;

    // Too Check token Exixtance
    mapping (uint => bool) _tokeExistance;
    
    modifier TokenNotExist(uint nftId){
        require(_tokeExistance[nftId]==false , "Token Already Exists");
        _;
    }
    modifier contractIsNotPaused(){
        require (IsPaused == false, "Contract is Paused" );
        _;
    }

    function CheckNftPrice(address owner, uint tokenID) public view returns(uint){
        return NFT_Price[owner][tokenID];
    }

    modifier OnlyOwner {
        require(msg.sender == contractOwner, "Only Owner can Access");
        _;
    }

    bool public IsPaused = true;
    address payable public  contractOwner;
    string private _name;
    
    constructor (string memory name){
        _name = name;
        contractOwner = payable(msg.sender);
    }

    /* Direct Minting on Blockchain 
    ** No Fee and Taxes on Minting
    ** Want to mint his own Address direct BVlockchain
    ** TokenURI is IPFS hash and will Get from Web3
    */
    function Mint (uint tokenId, uint noOfCopies,  bytes memory data, string memory tokenURI, uint RoyaltyValueOfMinter ) contractIsNotPaused TokenNotExist(tokenId)public {
        _mint(_msgSender(), tokenId, noOfCopies, data);
        TokenURI[tokenId] = tokenURI;
        _setTokenRoyalty(payable(msg.sender),tokenId,payable(msg.sender), RoyaltyValueOfMinter);
    }

    // localy Minted and Want to Mint directlty on Purchaser Address
    // Will Accept Payments For NFTs 
    // Deduct Royalties and NFTES Fee
    // Buyer Is Insiating Transaction himself
    // MinterAddress, RoyaltyValueOfMinter, NftPrice will get from Web3
    function mintLazyMintedNfts (address to, uint tokenID, uint noOfCopies, bytes memory data, string memory tokenURI, uint NftPrice, address payable MinterAddress, uint RoyaltyValueOfMinter) public payable{
        require(IsPaused == false, "Contract is Paused");
        require(msg.value>=NftPrice*noOfCopies, "Error! Insufficient Balance ");
        _mint(to, tokenID, noOfCopies, data);
        TokenURI[tokenID] = tokenURI;
        NFT_Price[to][tokenID]= NftPrice;
        _setTokenRoyalty(to, tokenID,MinterAddress, RoyaltyValueOfMinter);
        //Send Amount to Local Minter
        // Deduct Royalties
        _royaltyAndNFTESFee(NftPrice*noOfCopies, RoyaltyValueOfMinter, MinterAddress, MinterAddress );
    }
    // Batch Minting Public Function
    // Direct minting on Blockchain 
    function MintBatch(address to, uint[] memory tokenIds, uint[] memory noOfCopiesOfNfts, string[] memory TokenUriArr, bytes memory data, uint[] memory RoyaltyValue) external{
        
        require(IsPaused == false, "Contract is Paused");
        require(tokenIds.length == TokenUriArr.length, "TokenURI and Token ID Length Should be Same");
        _mintBatch(to, tokenIds, noOfCopiesOfNfts, TokenUriArr ,data, RoyaltyValue );
    }

    //Batch Minting Direct on Blockchain Internal Function
    function _mintBatch(address to,uint256[] memory tokenIds,uint256[] memory amounts,string[] memory Uri,bytes memory data, uint[] memory RoyaltyValue) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(tokenIds.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        address operator = _msgSender();
        _beforeTokenTransfer(operator, address(0), to, tokenIds, amounts, data);
        //Add check that he is only able to Add tokens in his own NFts if ID exists already
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _balances[tokenIds[i]][to] += amounts[i];
            TokenURI[tokenIds[i]] = Uri[i];
            _setTokenRoyalty(to,tokenIds[i], payable(_msgSender()), RoyaltyValue[i]);
        }
        emit TransferBatch(operator, address(0), to, tokenIds, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, tokenIds, amounts, data);
    }

    function IncrementInExistingTokens(address tokenOwnerAddr, uint tokenID, uint noOfTokensToIncrement, bytes memory data) public {
        //Check TokenID Already has Balance or Not
        require(balanceOf(tokenOwnerAddr,tokenID)>0, "Error! Use Function With URI");
        //Only Owner of that Token can Increment check owner or token Now check Approved or not
        require(_msgSender() == tokenOwnerAddr || isApprovedForAll(tokenOwnerAddr, _msgSender()), "Only Owner and Approved Address can Increment");
        _mint(tokenOwnerAddr, tokenID, noOfTokensToIncrement , data);
    }

    /*  function BuyerOfNft
    **  Will Transfer NFTs and Deduct Amount and Will forward to Addresses 
    **  Will just Pay royalties 
    **  Get minter Address from Struct recipient 
    **  Get NFT price
    */
    function NFTESsafeTransferFrom(address from, address to, uint tokenID, uint noOfCopies, bytes memory data ) public payable{
        require(msg.value >= (NFT_Price[from][tokenID])*noOfCopies, "Error! insufficient Balance ");
        //require(msg.value >= _deductNFTESFee(NFT_Price[from][id]), "Error! Insufficient Balance");
        _safeTransferFrom(from, to, tokenID, noOfCopies, data);
        // struct memory obj = mapping [address][id];
        royaltyInfo memory royalties = _royalties[from][tokenID];
        //"from" is NFT Seller
        _royaltyAndNFTESFee( ((NFT_Price[from][tokenID])*noOfCopies), royalties.royalityPercentage, royalties.recipient, payable(from));
        // Change Ownership delete Exixting  mapping (address=>mapping(uint=>uint)) NFT_Price;
        delete NFT_Price[from][tokenID];
        NFT_Price[to][tokenID]= msg.value/noOfCopies;
        //Extra Portion
        _setTokenRoyalty(to, tokenID, royalties.recipient, royalties.royalityPercentage);
    } 
    

    //Function To Switch Sale State in Bool
    function SwitchSaleState() public OnlyOwner {
        if (IsPaused == true){
            IsPaused = false;
        }
        else {
            IsPaused = true;
        }
    }

    //To WithDraw All Ammount from Contract to Owners Address 
    function withdrawFromContract(address payable to, uint withdrawAmount) public payable OnlyOwner {
        uint Balance = address(this).balance;
        require(Balance > 0 wei, "Error! No Balance to withdraw"); 
        require (withdrawAmount<Balance, "Withdraw Amount cannot be greater than available Balance");
        to.transfer(withdrawAmount);
    }   

    //To Check Contract Balance in Wei
    function ContractBalance() public view OnlyOwner returns (uint){
        return address(this).balance;
    }
    //Return Tokens IPFS URI against Address and ID
    function TokenUri(uint id) public view returns(string memory){
        require(bytes(TokenURI[id]).length != 0, "Token ID Does Not Exist");
        return TokenURI[id];
    }

    //Extra Function For Testing
    // function checkFirstMinter(address CurrentOwneradress, uint t_id ) view public returns(royaltyInfo memory){
    //     royaltyInfo memory object = _royalties[CurrentOwneradress][t_id];
    //     return object;
    // }

    // function PlaceNftForOpenBidding(){
    // }
    // function PlaceNftForTimedAuction(){
    // }
    // function PlaceNftForFixedAmount(){
    // }


}
