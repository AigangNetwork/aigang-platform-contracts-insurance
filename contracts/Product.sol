pragma solidity ^0.4.23;

import "./utils/OwnedWithExecutor.sol";
import "./utils/SafeMath.sol";
import "./utils/BytesHelper.sol";
import "./interfaces/IERC20.sol";
//import "./PremiumCalculator.sol";

interface IProduct {
    function addPolicy(bytes32 _id, uint32 _utcStart, uint32 _utcEnd, uint _calculatedPayout, string _properties) public;
    function claim(bytes32 _policyId, string _properties) public;
}

contract Product is Owned, IProduct {
    using SafeMath for uint;
    using BytesHelper for bytes;

    event PolicyAdd(bytes32 indexed _policyId);
    event Claim(bytes32 indexed _policyId, uint _amount);    
    event Cancel(bytes32 indexed _policyId, uint _amount);    
    event PremiumCalculatorChange(address _old, address _new);
    event PaymentReceived(bytes32 indexed _policyId, uint _amount);

    // TODO: limit policies or payouts amoun or others limits in code not contracts.    
    struct Policy {
        address owner;
        uint32 utcStart;
        uint32 utcEnd;
        uint premium;
        uint calculatedPayout;
        string properties;
        // claim
        uint payout;
        uint32 utcPayoutDate;
        string claimProperties;
        bool isPaidOut;
        bool isCanceled;
    }
    
    address public token;
    address public premiumCalculator;
    uint public utcProductStartDate;
    uint public utcProductEndDate;

    bool public paused = true;
    
    uint public policiesCount;
    uint public policiesTotalCalculatedPayouts;
    uint public policiesPayoutsCount;
    uint public policiesTotalPayouts;
        
    mapping(bytes32 => Policy) public policies;

    modifier notPaused() {
        require(paused == false, "Contract is paused");
        _;
    }

    modifier senderIsToken() {
        require(msg.sender == address(token));
        _;
    }

     modifier policyValidForPayout(bytes32 _policyId) {
        require(policies[_policyId].owner != address(0), "Owner is not valid");       
        require(policies[_policyId].payout == 0, "Payout already done");
        _;
    }
   
    function initialize(address _premiumCalculator, address _token, uint _utcProductStartDate, uint _utcProductEndDate) external onlyOwner {
        premiumCalculator = _premiumCalculator;
        token = _token;
        utcProductStartDate = _utcProductStartDate; 
        utcProductEndDate = _utcProductEndDate;
        paused = false;
    }

    function addPolicy(bytes32 _id, uint32 _utcStart, uint32 _utcEnd, uint _calculatedPayout, string _properties) public onlyAllowed notPaused {
        // TODO add theck it is payed
        policies[_id].utcStart = _utcStart;
        policies[_id].utcEnd = _utcEnd;
        policies[_id].calculatedPayout = _calculatedPayout;
        policies[_id].properties = _properties;

        policiesCount++;
        policiesTotalCalculatedPayouts = policiesTotalCalculatedPayouts.add(_calculatedPayout);

        emit PolicyAdd(_id);
    }

    /// Called by token contract after Approval: this.TokenInstance.methods.approveAndCall()
    function receiveApproval(address _from, uint _amountOfTokens, address _token, bytes _data) 
            external 
            senderIsToken
            notPaused {
        require(_amountOfTokens > 0, "amount should be > 0");
        bytes32 policyId = _data.bytesToBytes32();
        policies[policyId].owner = _from;

        require(policies[policyId].owner != address(0), "not valid policy owner");
        require(policies[policyId].premium == 0, "not valid policyId");

        // Transfer tokens from sender to this contract
        require(IERC20(token).transferFrom(_from, address(this), _amountOfTokens), "Tokens transfer failed.");
   
        policies[policyId].premium = _amountOfTokens;
        policies[policyId].owner = _from;

        emit PaymentReceived(policyId, _amountOfTokens);
    }
          
    function claim(bytes32 _policyId, string _properties) public 
            onlyAllowed 
            notPaused
            policyValidForPayout(_policyId) { 
      
        require(IERC20(token).balanceOf(this) >= policies[_policyId].calculatedPayout, "Contract balance is to low");

        policies[_policyId].isPaidOut = true;
        policies[_policyId].utcPayoutDate = uint32(now);
        policies[_policyId].payout = policies[_policyId].calculatedPayout;
        policies[_policyId].claimProperties = _properties;

        policiesPayoutsCount++;
        policiesTotalPayouts = policiesTotalPayouts.add(policies[_policyId].payout);

        assert(IERC20(token).transfer(policies[_policyId].owner, policies[_policyId].payout));

        emit Claim(_policyId, policies[_policyId].payout);
    }

    function cancel(bytes32 _policyId) public 
            onlyAllowed 
            notPaused
            policyValidForPayout(_policyId) {

        require(IERC20(token).balanceOf(this) >= policies[_policyId].calculatedPayout, "Contract balance is to low");

        policies[_policyId].isCanceled = true;
        policies[_policyId].utcPayoutDate = uint32(now);
        policies[_policyId].payout = policies[_policyId].premium;

        policiesPayoutsCount++;
        policiesTotalPayouts = policiesTotalPayouts.add(policies[_policyId].payout);

        assert(IERC20(token).transfer(policies[_policyId].owner, policies[_policyId].payout));

        emit Cancel(_policyId, policies[_policyId].payout);
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

   function tokenBalance() public view returns (uint) {
         return IERC20(token).balanceOf(this);
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