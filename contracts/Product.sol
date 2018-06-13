pragma solidity ^0.4.24;

import "./utils/Owned.sol";
import "./utils/SafeMath.sol";
import "./PremiumCalculator.sol";

contract IProduct {
    function addPolicy() public;
    function addClaim() public;
}

contract Ptoduct is Owned, IProduct {
    uint public fee;
    address public token;
    IPremiumCalculator public premiumCalculator;

    bool public paused;
    
    enum PolicyStatus {
        NotSet,
        Valid,
        Claimed
    }
    
    uint public policyCount;
    uint public policyPayoutsCount;
    
    struct Policy {
        uint id;
        uint deviceId; // TODO: check it is needed
        address owner;
        uint utcStart;
        uint utcEnd;
        PolicyStatus status;
        uint premium;
        uint payout; // TODO: decide payout configuration
        uint32 IPFSHash;
    };
    
    struct Claim {
        uint policyId;
        uint date;
        uint payout;
        uint32 IPFSHash;
    }
    
    Policy[] public policies; // todo check mapping
    
    function initialize(address _premiumCalculator, uint _fee) external onlyOwner {
        premiumCalculator = IPremiumCalculator(_premiumCalculator);
        fee = _fee;
        paused = false;
    };
    
    function addPolicy() public onlyOwner {
        emit Policy;
    };
    
    function addClaim() public onlyOwner {
        emit Claim;
    };
    
    event Policy(uint indexed _policyId, address indexed _owner, uint _amount);
    event Claim(uint indexed _policyId, address indexed _owner, uint _amount);    
    event PremiumCalculatorChanged(address _old, address _new); 
}