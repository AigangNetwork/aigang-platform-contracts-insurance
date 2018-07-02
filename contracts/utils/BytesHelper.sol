pragma solidity ^0.4.23;

library BytesHelper {
    function bytesToBytes32(bytes memory source) pure internal returns (bytes32 result) {
        assembly {
            result := mload(add(source, 32))
        }
    }
}