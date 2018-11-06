pragma solidity ^0.4.23;

library Strings {
    function equal(string memory _a, string memory _b) pure internal returns (bool) {
        return (sha3(_a) == sha3(_b));
    }
}