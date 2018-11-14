pragma solidity ^0.4.24;

import "./SafeMath.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";//usage of library

contract Loan is Ownable {
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
        
    constructor() public{
        
    }
        
    function createLoan(address exporterAddr, uint256 loanAmountVal, address letterOfCreditAddr) public{
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

    function bidForLoan(uint256 interestRate) public payable{
        require(equal(biddingStatus,biddingStatusArray[0]),errMsg[4]); //Requires to be started
        Bid memory current = Bid(msg.sender, SafeMath.mul(interestRate,1 ether));
        bid.push(current);
        
    }
    
    function processWinningBid() public{
        require(equal(biddingStatus, biddingStatusArray[0]), errMsg[4]); //must be started then execute
        uint256 lowestRate;
        address winningBank;
        bool initialize = false;
        biddingStatus = biddingStatusArray[1]; //Closed
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

    }


    function issueLoan() public payable{

        uint256 etherVal = SafeMath.mul(msg.value, 1 ether);

        if(!equal(biddingStatus,biddingStatusArray[1])){
            revert(errMsg[0]);
        }else if(winningBid.issued){
            revert(errMsg[0]);
        }else if(msg.sender != winningBid.loaningBank){
            revert(errMsg[0]);
        }else if(etherVal != loanAmount){
            revert(errMsg[1]);
        }
        
        
        exporter.transfer(etherVal); //xfer loan to exporter
        winningBid.issued = true; //set issued to true
  
    }
    
    function repayLoan() public payable{

        uint256 etherVal = SafeMath.mul(msg.value, 1 ether);

        if(msg.sender != exporter){
            revert(errMsg[0]);
        }else if(winningBid.paid){
            revert(errMsg[0]);
        }else if( etherVal != SafeMath.add(loanAmount, winningBid.interestRate)){
            revert(errMsg[1]);
        }
        
        winningBid.loaningBank.transfer(etherVal);
        winningBid.paid = true;
        
    }
    
        
    //Getters - constant doesn't modifiy state
    function retrieveExporter() public view returns  (address){
        return exporter;
    }
    
    function retrieveLetterOfCreditAddress() public view returns  (address){
        return letterOfCredit;
    }


    function retrieveRepaymentAmount() public view returns  (uint256){
        return SafeMath.add(loanAmount, winningBid.interestRate);
    }
    
    function retrieveLoanAmount() public view returns  (uint256){
        return loanAmount;
    }
    
    function retrieveLoaningBank() public view returns  (address){
        return winningBid.loaningBank;
    }
    
    
    function retrieveBiddingStatus() public view returns  (string){
        return biddingStatus;
    }
    
    
    function equal(string _a, string _b) private pure returns (bool) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        return keccak256(a) == keccak256(b) ;
    }
	
	function retrieveIssue() public view returns  (bool){
        return winningBid.issued;
    }
	
	function retrievePaid() public view returns  (bool){
        return winningBid.paid;
    }

    function retrieveInterestRate() public view returns  (uint256){
        return winningBid.interestRate;
    }
	
	

    
}