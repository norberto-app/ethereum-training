pragma solidity ^0.5.15;

contract SomeContract {
    uint public myUint = 10;
    
    function setMyUint(uint value) public {
        myUint = value;
    }
    
}