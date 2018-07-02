pragma solidity ^0.4.23;

import "../../contracts/utils/BytesHelper.sol";

contract MocBytesHelper {
  using BytesHelper for bytes;

  function Ping() external pure returns (bytes32 result) {
    result = "Pong";
  }

  function BytesToBytes32(bytes _value) external pure returns (bytes32 result) {
    result = _value.bytesToBytes32();
  }
}