pragma solidity ^0.4.13;

library BytesHelper {
    function bytesToBytes32(bytes memory source) pure internal returns (bytes32 result) {
        assembly {
            result := mload(add(source, 32))
        }
    }
}

contract MocBytesHelper {
  using BytesHelper for bytes;

  function Ping() external pure returns (bytes32 result) {
    result = "Pong";
  }

  function BytesToBytes32(bytes _value) external pure returns (bytes32 result) {
    result = _value.bytesToBytes32();
  }
}

