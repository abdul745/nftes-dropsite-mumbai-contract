// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Test {
    uint a;
   // address d = 0x12345678901234567890123456789012;

    function Test(uint testInt) public  { a = testInt;}

    event Event(uint indexed b, bytes32 c);

    event Event2(uint indexed b, bytes32 c);

    function foo(uint b, bytes32 c) returns(address) {
        Event(b, c);
        return d;
    }
}