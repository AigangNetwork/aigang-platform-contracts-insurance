pragma solidity ^0.4.23;

contract Owned {
    address public owner;
    address public executor;
    address public newOwner;
  
    event OwnershipTransferred(address indexed _from, address indexed _to);
    event ExecutorTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
        executor = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "User is not owner");
        _;
    }

    modifier onlyAllowed {
        require(msg.sender == owner || msg.sender == executor, "Not allowed");
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function transferExecutorOwnership(address _newExecutor) public onlyOwner {
        emit ExecutorTransferred(executor, _newExecutor);
        executor = _newExecutor;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}