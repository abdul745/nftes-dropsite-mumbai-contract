// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract NFTESErc20 {

    event RoyaltiesTransfer(uint, uint, uint);
    struct royaltyInfo {
        address payable recipient;
        uint24 amount;
    }
    mapping (address => uint) deposits;
    mapping(uint256 => royaltyInfo) _royalties;
    mapping (address=>bool) NFTESWhiteList;
    function _setTokenRoyalty(uint256 tokenId,address payable recipient,uint256 value) internal {
        require(value <= 50, "Error! Too high Royalties");
        _royalties[tokenId] = royaltyInfo(recipient, uint24(value));
    }

    function _royaltyAndNFTESFee (uint _NftPrice, uint percentage, address payable minterAddress, address payable NftSeller) internal  {
        uint _TotalNftPrice = msg.value;                                // require(msg.value >= NftPrice[NftId], "Error! Insufficent Balance");
        uint _NFTESFee = _deductNFTESFee(_NftPrice);
        uint _minterFee = _SendMinterFee(_NftPrice , percentage,  minterAddress);
        _TotalNftPrice = _TotalNftPrice - _NFTESFee - _minterFee;    //Remaining Price After Deduction  
        _transferAmountToSeller( _TotalNftPrice, NftSeller);            // Send Amount to NFT Seller after Tax deduction
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
        uint AmountToSend = _NftPrice*Percentage/100;           //Calculate Minter percentage and Send to his Address from Struct
        recepient.transfer(AmountToSend);                       // Send this Amount To Transfer Address from Contract balacne
        return AmountToSend;
    }
    function depositBidAmmount(address payee,uint amountToDeposit) internal {
        require(msg.value == amountToDeposit, "Error while Deposit");
        deposits[payee] += amountToDeposit;
    }
    function deductAmount(address from, uint amount) internal {
        require(deposits[from]>0 && amount <= deposits[from] , "Error! Low Balance");
        deposits[from] -= amount;
    }

}