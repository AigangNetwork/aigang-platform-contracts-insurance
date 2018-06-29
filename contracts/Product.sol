pragma solidity ^0.4.23;

import "./utils/OwnedwithExecutor.sol";
import "./utils/SafeMath.sol";
import "./interfaces/IERC20.sol";
//import "./PremiumCalculator.sol";

contract IProduct {
    function addPolicy() public;
    function addClaim() public;
}

contract Product is Owned, IProduct {
    using SafeMath for uint;

    event PolicyAdd(bytes32 indexed _policyId, uint _amount);
    event Claim(bytes32 indexed _policyId, uint _amount);    
    event Cancel(bytes32 indexed _policyId, uint _amount);    
    event PremiumCalculatorChange(address _old, address _new);

    // TODO: limit policies ar payouts amoun or others limits in code not contracts.    
    struct Policy {
        address owner;
        uint utcStart;
        uint utcEnd;
        uint premium;
        uint calculatedPayOut;
        uint IPFSHash; // todo check how to store refference to any ETH storage
        PayOutReason payOutReason;
        // claim
        uint payOut;
        uint utcPayOutDate;
        uint claimIPFSHash;
    }

    enum PayOutReason {
        NotSet,
        Claim,
        Cancel
    }
    
    address public token;
    address public premiumCalculator;
    uint public utcProductStartDate;
    uint public utcProductEndDate;

    bool public paused = true;
    
    uint public policiesCount;
    uint public policiesTotalCalculatedPayOuts;
    uint public policiesPayoutsCount;
    uint public policiesTotalPayOuts;
        
    mapping(bytes32 => Policy) public policies;

    modifier notPaused() {
        require(paused == false, "Contract is paused");
        _;
    }

     modifier policyValidForPayOut(bytes32 _policyId) {
        require(policies[_policyId].owner != address(0), "Owner is not valid");       
        require(policies[_policyId].payOut == 0, "PayOut already done");
        _;
    }
   
    function initialize(address _premiumCalculator, address _token, uint _utcProductStartDate, uint _utcProductEndDate) external onlyOwner {
        premiumCalculator = _premiumCalculator;
        token = _token;
        utcProductStartDate = _utcProductStartDate; 
        utcProductEndDate = _utcProductEndDate;
        paused = false;
    }

    function addPolicy(bytes32 _id, address _owner, uint _utcStart, uint _utcEnd, uint _premium, uint _calculatedPayOut, uint ipfsHash) public onlyAllowed notPaused {
        require(_owner != address(0), "Owner is not valid");

        policies[_id].owner = _owner;
        policies[_id].utcStart = _utcStart;
        policies[_id].utcEnd = _utcEnd;
        policies[_id].premium = _premium;
        policies[_id].calculatedPayOut = _calculatedPayOut;

        policiesCount++;
        policiesTotalCalculatedPayOuts = policiesTotalCalculatedPayOuts.add(_calculatedPayOut);

        emit PolicyAdd(_id, _premium);
    }
          
    function claim(bytes32 _policyId, uint ipfsHash) public 
            onlyAllowed 
            notPaused
            policyValidForPayOut(_policyId) { 
      
        require(IERC20(token).balanceOf(this) >= policies[_policyId].calculatedPayOut, "Contract balance is to low");

        policies[_policyId].payOutReason = PayOutReason.Claim;
        policies[_policyId].utcPayOutDate = now;
        policies[_policyId].payOut = policies[_policyId].calculatedPayOut;

        policiesPayoutsCount++;
        policiesTotalPayOuts = policiesTotalPayOuts.add(policies[_policyId].payOut);

        assert(IERC20(token).transfer(policies[_policyId].owner, policies[_policyId].payOut));


        emit Claim(_policyId, policies[_policyId].payOut);
    }

    function cancel(bytes32 _policyId) public 
            onlyAllowed 
            notPaused
            policyValidForPayOut(_policyId) {

        require(IERC20(token).balanceOf(this) >= policies[_policyId].calculatedPayOut, "Contract balance is to low");

        policies[_policyId].payOutReason = PayOutReason.Cancel;
        policies[_policyId].utcPayOutDate = now;
        policies[_policyId].payOut = policies[_policyId].premium;

        policiesPayoutsCount++;
        policiesTotalPayOuts = policiesTotalPayOuts.add(policies[_policyId].payOut);

        assert(IERC20(token).transfer(policies[_policyId].owner, policies[_policyId].payOut));

        emit Cancel(_policyId, policies[_policyId].payOut);
    }

    function updatePremiumCalculator(address _newCalculator) public onlyOwner {
        emit PremiumCalculatorChange(premiumCalculator, _newCalculator);
        premiumCalculator = _newCalculator;
    }      
    

    //////////
    // Safety Methods
    //////////
    function () public payable {
        require(false);
    }

    function withdrawETH() external onlyOwner {
        owner.transfer(address(this).balance);
    }

    function withdrawTokens(uint _amount, address _token) external onlyOwner {
        IERC20(_token).transfer(owner, _amount);
    }

    function pause(bool _paused) external onlyOwner {
        paused = _paused;
    }
}