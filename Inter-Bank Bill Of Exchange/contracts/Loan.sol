pragma solidity ^0.4.24;
//pragma experimental ABIEncoderV2;
//Ask: Referencing the L/C address or the whole class?
//Left with converting all to percentage..
//Adding the date to process smart 
//We can also automate the send ether after processing..

import "./SafeMath.sol";

contract SimpleLoan {
    using SafeMath for uint256;
    
    address exporter;
    address letterOfCredit;
    uint256 loanAmount;
    string biddingStatus;
    string[] errMsg;
    string[] biddingStatusArray;

    address[] biddingBanks;
    uint256[] biddingInterestRate;
    
    Bid[] public bid;
    struct Bid{
        address biddingAddress;
        uint256 interestRate;
    }
    
    WinningBid public winningBid;
    struct WinningBid {
        address loaningBank;
        uint256 interestRate;
        bool issued;
        bool paid;
    }
        
    constructor(address exporterAddr, uint256 loanAmountVal, address letterOfCreditAddr) public{
        biddingStatusArray = ["Started","Closed"];
        errMsg = [
                "Unauthorized Transaction",//0
                "Loan value do not match", //1
                "Transaction Failed",      //2
                "Transaction Successful",  //3
                "Unauthorized Command"     //4
            ];
        exporter = exporterAddr;
        letterOfCredit = letterOfCreditAddr; //removed temporary for easy testing..
        loanAmount = SafeMath.mul(loanAmountVal, 1 ether);
        biddingStatus = biddingStatusArray[0];
     
        
      
    }
    
    //Ask: How to disable bidforloan being clicked again.
    function bidForLoan(uint256 interestRate) public payable{
        require(equal(biddingStatus,biddingStatusArray[0]),errMsg[4]); //Requires to be started
        Bid memory current = Bid(msg.sender, SafeMath.mul(interestRate,1 ether));
        bid.push(current);
        
    }
    
    //someone has to pay for processing?
    //if the same rate then the first person gets the bid.
    //if the same address, the bidder bids will be overwritten? or assume that they wont bid again
    //ask: confirm is it surely got people bid? what if nobody bid, do we handle the case?
    function processWinningBid() public{
        require(equal(biddingStatus, biddingStatusArray[0]), errMsg[4]); //must be started then execute
        uint256 lowestRate;
        address winningBank;
        bool initialize = false;
        for(uint i = 0; i < bid.length; i++){
            if(initialize){
                if(bid[i].interestRate < lowestRate){
                    lowestRate = bid[i].interestRate;
                    winningBank = bid[i].biddingAddress;
                }
            }else{
                lowestRate = bid[i].interestRate;
                winningBank = bid[i].biddingAddress;
                initialize = true;
            }
        }

        winningBid = WinningBid(winningBank, lowestRate, false, false);
        biddingStatus = biddingStatusArray[1]; //Closed
    }


    function issueLoan() public payable{
        //require(equal(biddingStatus, biddingStatusArray[1]),errMsg[0]); //Closed - Unauthorized Transaction
        //require(!winningBid.issued, errMsg[0]);// Winning Bid must not be issued - Unauthorized Transaction
        //require(msg.sender == winningBid.loaningBank, errMsg[0]); //Not same bank - Unauthorized Transaction
        //require(msg.value == loanAmount, errMsg[1]); //- Answer question above: by right wont happen.. UI handle
        
        if(!equal(biddingStatus,biddingStatusArray[1])){
            revert(errMsg[0]);
        }else if(winningBid.issued){
            revert(errMsg[0]);
        }else if(msg.sender != winningBid.loaningBank){
            revert(errMsg[0]);
        }else if(msg.value != loanAmount){
            revert(errMsg[1]);
        }
        
        
        exporter.transfer(msg.value); //xfer loan to exporter
        winningBid.issued = true; //set issued to true
  
    }
    
    function repayLoan() public payable{
        //require(msg.sender == exporter, errMsg[0]); //Unauthroized Transaction
        //require(!winningBid.paid, errMsg[0]);//Unauthorized Transaction
        //require(msg.value == SafeMath.add(loanAmount, winningBid.interestRate), errMsg[1]); //Dont match value
        
        if(msg.sender != exporter){
            revert(errMsg[0]);
        }else if(winningBid.paid){
            revert(errMsg[0]);
        }else if(msg.value != SafeMath.add(loanAmount, winningBid.interestRate)){
            revert(errMsg[1]);
        }
        
        winningBid.loaningBank.transfer(msg.value);
        winningBid.paid = true;
        
    }
    
    uint256 data;
    function testFunc(uint256 interest) public payable{
        data = interest;
    }
    
    
        
    //Getters - constant doesn't modifiy state
    function retrieveExporter() constant returns (address){
        return exporter;
    }
    
    function retrieveLetterOfCreditAddress() constant returns (address){
        return letterOfCredit;
    }


    function retrieveRepaymentAmount() constant returns (uint256){
        return SafeMath.add(loanAmount, winningBid.interestRate);
    }
    
    function retrieveLoanAmount() constant returns (uint256){
        return loanAmount;
    }
    
    function retrieveLoaningBank() constant returns (address){
        return winningBid.loaningBank;
    }
    
    
    function retrieveBiddingStatus() constant returns (string){
        return biddingStatus;
    }
    
    
    function equal(string _a, string _b) private pure returns (bool) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        return keccak256(a) == keccak256(b) ;
    }

    
}