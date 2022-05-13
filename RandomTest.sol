//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;
contract RandomTest{
   uint8[] outputs; 
    function randomTest() public returns (uint8[] memory)
    {      
            uint index = random();
            uint8[10] memory nums;
            nums = [0,1,1,1,2,2,2,2,2,2];
            outputs.push(nums[index]);
            return outputs;
    }

    function random() internal view returns (uint) {
        //Only Returns 0,1,2
    uint randomnumber = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 10;
    return randomnumber;
    }

}