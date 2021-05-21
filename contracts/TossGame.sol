pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";
//import "https://raw.githubusercontent.com/smartcontractkit/chainlink/master/evm-contracts/src/v0.6/VRFConsumerBase.sol";

contract TossGame is VRFConsumerBase {
    
    bytes32 internal keyHash;
    
    uint256 internal fee;
    uint256 private randomResult;
    
    bool public result = false;

    mapping(address => uint256) private _addressToBalances;
    
    address private owner;

    event BetIsPlaced(address sender, uint256 amount, bool result, bool bet);
    
    /**
     * Constructor inherits VRFConsumerBase
     * 
     * Network: Kovan
     * Chainlink VRF Coordinator address: 0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9
     * LINK token address:                0xa36085F69e2889c224210F603D836748e7dC0088
     * Key Hash: 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4
     */
    constructor() 
        VRFConsumerBase(
            0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9, // VRF Coordinator
            0xa36085F69e2889c224210F603D836748e7dC0088  // LINK Token
        ) payable public
    {
        keyHash = 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4;
        fee = 0.1 * 10 ** 18; // 0.1 LINK
        
        owner = msg.sender; 
    
    }
    
    function getRandomNumber(uint256 userProvidedSeed) public returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(keyHash, fee, userProvidedSeed);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResult = randomness;
    }
    
    /**
     * Withdraw LINK from this contract
     * 
     * DO NOT USE THIS IN PRODUCTION AS IT CAN BE CALLED BY ANY ADDRESS.
     * THIS IS PURELY FOR EXAMPLE PURPOSES.
     */
    function withdrawLink() external {
        require(LINK.transfer(msg.sender, LINK.balanceOf(address(this))), "Unable to transfer");
    }

    
    //PLAYER functions
    
    //provide player balance
    function balanceOfPlayer() external view returns (uint256){
        require(msg.sender != owner);
        return _addressToBalances[msg.sender];
    }
    
    //place bet and pay money
    function placeBet(bool _bet) external payable{
        require(msg.value <= (address(this).balance/10) && msg.sender != owner);
        _addressToBalances[msg.sender] = msg.value;
        if(result == _bet){                                             
            _addressToBalances[msg.sender] += msg.value;
        }else{
            _addressToBalances[msg.sender] = 0;
        }
        emit BetIsPlaced(msg.sender, msg.value, result, _bet);
    }
    
    //player withdraws money
    function withdrawMoney() external{
        require(_addressToBalances[msg.sender] >=0 && msg.sender != owner);
        msg.sender.transfer(_addressToBalances[msg.sender]);
        delete _addressToBalances[msg.sender];
    }
    
    
    //GAME functions
    
    //provide balance of smart contract
    function gameBalance() external view returns (uint256){
        return address(this).balance;
    }
    
    
    //OWNER functions
    
    //provide funds to smart contract
    function provideFunds() external payable{
        require(msg.sender == owner);
        _addressToBalances[owner] = msg.value;
    }
    
    //Withdraw money from smart contract
    function withdrawContractMoney() external{
        require(msg.sender == owner);
        msg.sender.transfer(address(this).balance);
    }
}