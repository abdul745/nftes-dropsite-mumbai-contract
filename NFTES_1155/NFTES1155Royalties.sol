// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract NFTES1155Royalties {
    // uint public NFTESFee;
    event RoyaltiesTransfer(uint, uint, uint);
    struct royaltyInfo {
        address payable recipient;
        uint24 royalityPercentage;
    }
    mapping(address=>mapping(uint256 => royaltyInfo)) _royalties;
    mapping (address=>bool) NFTESWhiteList;
    // function setNFTESFee(uint )
    function _setTokenRoyalty(address owner, uint256 tokenId,address payable recipient,uint256 value) internal {
        require(value <= 50, "Error! Too high Royalties");
        _royalties[owner][tokenId] = royaltyInfo(recipient, uint24(value));
    }

    function _royaltyAndNFTESFee (uint _NftPrice, uint percentage, address payable minterAddress, address payable NftSeller) internal  {
        // require(msg.value >= NftPrice[NftId], "Error! Insufficent Balance");
        uint _TotalNftPrice = msg.value;
        uint _NFTESFee = _deductNFTESFee(_NftPrice);
        uint _minterFee = _SendMinterFee(_NftPrice , percentage,  minterAddress);
        //Remaining Price After Deduction  
        _TotalNftPrice = _TotalNftPrice - _NFTESFee - _minterFee;
        // Send Amount to NFT Seller after Tax deduction
        _transferAmountToSeller( _TotalNftPrice, NftSeller);
        emit RoyaltiesTransfer(_NFTESFee,_minterFee, _TotalNftPrice);
    }

    function _deductNFTESFee(uint Price) internal pure returns(uint) {
        require((Price/10000)*10000 == Price, "Error! Too small");
        return Price*25/1000;
    }
    
    function _transferAmountToSeller(uint amount, address payable seller) internal {
        seller.transfer(amount);
    }

    function _SendMinterFee(uint _NftPrice, uint Percentage, address payable recepient) internal returns(uint) {
        //Calculate Minter percentage and Send to his Address from Struct
        uint AmountToSend = _NftPrice*Percentage/100;
        // Send this Amount To Transfer Address from Contract balacne 
        recepient.transfer(AmountToSend);
        return AmountToSend;
    }
    
}