// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract NFTES1155Auction {  //is SpaceERC20 
    event availableForBids(uint, string) ;
    event removeFormSale (uint, string );
    enum status {NotOnSale ,onAuction, onBidding, OnfixedPrice }
    status public CurrentStatus;
    struct NftDetails{
        uint [] bidAmount;
        uint [] numOfCopies;
        address[] bidderAddress;
        uint startingPrice;
        uint startTime;
        uint endTime;
        bool Exists;
        // Using minimumPrice == minimumBid  
        uint minimumPrice;
        uint index;
        status salestatus;
    }
     // NftOwnerAddress to NftId to NftDetails (Struct) 
    mapping(address=>mapping(uint=>NftDetails)) Nft;
    modifier NftExist (address _owner, uint NftId){
        require(Nft[_owner][NftId].Exists == true , "Not Owner of Nft or Does't Exist ");
        _;
    }
    modifier notOnSale (address owner,uint nftId) {
        require(Nft[owner][nftId].salestatus == status.NotOnSale, "Error! Nft is Already on Sale");
        _;
    }
    modifier onBidding(address owner,uint nftId){
        require(Nft[owner][nftId].salestatus == status.onBidding , "Error! NFT is Not Available for Biding");
        _;
    }
    modifier onSale (address nftOwnerAddress ,uint nftId) {
        require( Nft[nftOwnerAddress][nftId].salestatus != status.NotOnSale, "Error! Nft is Not on Sale");
        _;
    }

    modifier onFixedPrice (address owner, uint nftId){
        require( Nft[owner][nftId].salestatus == status.OnfixedPrice, "NFT is Not Available for Fixed Price");
        _;
    }
//    


//     //Place NFT to Accept Bids
    function _placeNftForBids(address _owner, uint NftId ) notOnSale(_owner,NftId) NftExist(_owner , NftId) internal {
        CurrentStatus = status(2);
        // NftDetails storage NftDetailobj = Nft[NftId];   I think it will create Storage Obj automatically,  Nft[NftId].salestatus  
        Nft[_owner][NftId].salestatus = CurrentStatus;
        emit availableForBids (NftId, "Accepting Bids");
    }



//     // function putOnSale(uint NftId) internal {
//     //     require(Nft[NftId].IsonSale == false, "Not On Sale");
//     //     Nft[NftId].IsonSale = true;
//     // }
    function _pushBidingValues (address nftOwnerAddress,address bidderAddress, uint nftId, uint _bidAmount, uint _numOfCopies) onBidding(nftOwnerAddress,nftId) internal{
        Nft[nftOwnerAddress][nftId].bidAmount.push(_bidAmount);
        Nft[nftOwnerAddress][nftId].bidderAddress.push(bidderAddress);
        Nft[nftOwnerAddress][nftId].numOfCopies.push(_numOfCopies);
    }
    function _placeNftForFixedPrice(address owner ,uint nftId, uint Fixedamount )notOnSale(owner, nftId) NftExist(owner , nftId) internal{ 
        CurrentStatus = status(3);
        Nft[owner][nftId].salestatus = CurrentStatus;
        Nft[owner][nftId].minimumPrice = Fixedamount;
    }

    function _removeFromSale(address ownerAddress, uint nftId) NftExist(ownerAddress,nftId) onSale(ownerAddress,nftId) internal {
        // check Already on Sale 
        CurrentStatus = status(0);
        Nft[ownerAddress][nftId].salestatus = CurrentStatus;
        emit removeFormSale(nftId , "Error! NFT is removed from Sale ");
    }
    function CheckNftStatus(address nftOwner, uint nftId) view external returns(status){
        return Nft[nftOwner][nftId].salestatus;
    }

}