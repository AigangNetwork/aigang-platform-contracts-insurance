pragma solidity ^0.4.23;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "./../mocs/MocBytesHelper.sol";

contract TestMocBytesHelper {

  function test_happyflow() public {
    MocBytesHelper bytesHelper = new MocBytesHelper();
    
    bytes memory value =  hex"11";

    bytes32 result = bytesHelper.BytesToBytes32(value);

    Assert.equal(result, "11", "should be 11");
  }
}