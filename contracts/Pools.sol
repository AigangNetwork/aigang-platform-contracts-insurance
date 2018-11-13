pragma solidity ^0.4.23;

import "./utils/OwnedWithExecutor.sol";
import "./utils/SafeMath.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IPrizeCalculator.sol";

// BUIDL IN PROGRESS

contract Pools is Owned {
    using SafeMath for uint;  

    event Initialize(address _token);
    event PoolAdded(bytes32 _destination);
    event ContributionAdded(bytes32 _poolId, bytes32 _contributionId);
    event PoolStatusChange(PoolStatus _oldStatus, PoolStatus _newStatus);
    event Paidout(bytes32 _poolId, bytes32 _contributionId);
    event Withdraw(uint _amount);

    uint8 public constant version = 1;
    bool public paused = true;
    address public token;
    
    mapping(bytes32 => Pool) public pools;
    
    struct Pool {  
        uint contributionStartUtc;
        uint contributionEndUtc;
        address destination;
        PoolStatus status;
        uint amountLimit;
        uint amountCollected;
        uint amountDistributing;
        uint paidout;
        mapping(bytes32 => Contribution) contributions;
        address prizeCalculator;
    }
    
    struct Contribution {  
        address owner;
        uint amount;
        uint paidout;
    }
    
    enum PoolStatus {
        NotSet,       // 0
        Active,       // 1
        Distributing, // 2
        Funded,       // 3 
        Paused        // 4
    }  

    modifier contractNotPaused() {
        require(paused == false, "Contract is paused");
        _;
    }

    modifier senderIsToken() {
        require(msg.sender == address(token));
        _;
    }
    
    modifier validatePool(bytes32 _poolId, uint _amount) {
        require(pools[_poolId].status == PoolStatus.Active, "Status should be active");
        require(pools[_poolId].contributionStartUtc < now, "Contribution is not started");    
        require(pools[_poolId].contributionEndUtc > now, "Contribution is ended"); 
        require(pools[_poolId].amountLimit == 0 || 
                pools[_poolId].amountLimit >= pools[_poolId].amountCollected.add(_amount), "Contribution limit reached"); 
        _;
    }

    function initialize(address _token) external onlyOwnerOrSuperOwner {
        token = _token;
        paused = false;
        emit Initialize(_token);
    }

    function addPool(bytes32 _id, 
        address _destination, uint _contributionStartUtc, uint _contributionEndUtc, uint _amountLimit, address _prizeCalculator) 
        external 
        onlyOwnerOrSuperOwner 
        contractNotPaused {
        
        pools[_id].contributionStartUtc = _contributionStartUtc;
        pools[_id].contributionEndUtc = _contributionEndUtc;
        pools[_id].destination = _destination;
        pools[_id].status = PoolStatus.Active;
        pools[_id].amountLimit = _amountLimit;
        pools[_id].prizeCalculator = _prizeCalculator;
        
        emit PoolAdded(_id);
    }
    
    function setPoolStatus(bytes32 _poolId, PoolStatus _status) public onlyOwnerOrSuperOwner {
        emit PoolStatusChange(pools[_poolId].status, _status);
        pools[_poolId].status = _status;
    }
    
     function setPoolDistributing(bytes32 _poolId, uint _amountDistributing) external onlyOwnerOrSuperOwner {
        setPoolStatus(_poolId, PoolStatus.Distributing);
        pools[_poolId].amountDistributing = _amountDistributing;
    }
    
    // TODO refactor to token approveCallback
    function addContribution(bytes32 _poolId, bytes32 _contributionId, address _contributor, uint _amount) 
        external
        contractNotPaused 
        validatePool(_poolId, _amount) {
        
        // TODO check sender is aix token
        
        require(pools[_poolId].contributions[_contributionId].amount == 0, "Amount should be 0");
        
        pools[_poolId].contributions[_contributionId].owner = _contributor;
        pools[_poolId].contributions[_contributionId].amount = _amount;
        
        emit ContributionAdded(_poolId, _contributionId);
    }
    
    function transferToDestination(bytes32 _poolId) external onlyOwnerOrSuperOwner {
        assert(IERC20(token).transfer(pools[_poolId].destination, pools[_poolId].amountCollected));
        setPoolStatus(_poolId,PoolStatus.Funded);
    }
    
     function payout(bytes32 _poolId, bytes32 _contributionId) public contractNotPaused {
        require(pools[_poolId].status == PoolStatus.Distributing, "Pool should be Distributing");
        require(pools[_poolId].amountDistributing > pools[_poolId].paidout, "Pool should be not empty");
        

        Contribution storage con = pools[_poolId].contributions[_contributionId];
        assert(con.paidout == 0);
        
        IPrizeCalculator calculator = IPrizeCalculator(pools[_poolId].prizeCalculator);
    
        uint winAmount = calculator.calculatePrizeAmount(
            pools[_poolId].amountDistributing,
            pools[_poolId].amountCollected,  
            con.amount
        );
      
        assert(winAmount > 0);
        con.paidout = winAmount;
        pools[_poolId].paidout = pools[_poolId].paidout.add(winAmount);
        assert(IERC20(token).transfer(con.owner, winAmount));
        emit Paidout(_poolId, _contributionId);
    }
    
    
    // ////////
    // Safety Methods
    // ////////
    function () public payable {
        require(false);
    }

    function withdrawETH() external onlyOwnerOrSuperOwner {
        uint balance = address(this).balance;
        owner.transfer(balance);
        emit Withdraw(balance);
    }

    function withdrawTokens(uint _amount, address _token) external onlyOwnerOrSuperOwner {
        assert(IERC20(_token).transfer(owner, _amount));
        emit Withdraw(_amount);
    }

    function pause(bool _paused) external onlyOwnerOrSuperOwner {
        paused = _paused;
    }
}