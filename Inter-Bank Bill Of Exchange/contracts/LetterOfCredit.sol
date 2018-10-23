pragma solidity ^0.4.24;
import "./SafeMath.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";//usage of library


contract LetterOfCredit is Ownable{
   
    using SafeMath for uint256;
    
    address exporter;
    address importer;
    address shipper;
    address issuingBank;
    address inspectorForBuyer;
    address inspectorForSeller;
    string shipmentStatus; 
    string inspectionForExporterStatus;
    string inspectionForImporterStatus;
    string[] shipmentStatusArray;
    string[] inspectionForExporterStatusArray;
    string[] errMsg;
    uint256 contractPrice;
    BillOfExchange public boe; 
    BillOfLading public bol;
    CertificateOfInspection coiFromExporter;
    CertificateOfInspection coiFromImporter;
    
   /// event PaymentMade(uint paymentAmt, address payer);
   /// event CertificationDone(bool certified, address sig);
                                            
    struct BillOfExchange {
        address holder;
        uint256 contractPrice; 
    }

    struct BillOfLading {
        address holder;
    }

    struct CertificateOfInspection {
        bool certified;
        address signature;
    }

    constructor() public {
    }


    function createBOE(address exporterAddr, address importerAddr, address shipperAddr, address inspectorAddr, address issuingBankAddr, uint256 contractVal) public {
        
        shipmentStatusArray = ["Pending Shipment", "In Port", "Ship out", "Collected"];
        inspectionForExporterStatusArray=["Requested","Accepted","Rejected"];

        
        errMsg = [  
                    "Unauthorised Transaction",                                 //errMsg[0]
                    "Sent value does not equal Contract Value"                 //errMsg[1]
                ];

        exporter = exporterAddr; 
        importer = importerAddr; 
        shipper = shipperAddr;
        inspectorForBuyer = inspectorAddr;
        issuingBank=issuingBankAddr;

        contractPrice = SafeMath.mul(contractVal, 1 ether); // Stores ether value as wei 
        shipmentStatus = "default";
        inspectionForExporterStatus="default";
        inspectionForImporterStatus="default";


        bol = BillOfLading ({
            holder: 0
        });
        
        boe = BillOfExchange({
            holder: 0,
            contractPrice: contractVal
        });
        
        coiFromExporter = CertificateOfInspection({
            certified: false,
            signature: 0
        });

        coiFromImporter = CertificateOfInspection({
            certified: false,
            signature: 0
        });

    }

    /// Issuing bank issues letter of credit///
    function issueLetterOfCredit() public payable {
        require(msg.sender==issuingBank,errMsg[0]);
        boe.holder = exporter;
    }

    /// Exporter requests inspection ///
    function requestInspection() public {
        require(msg.sender==exporter,errMsg[0]);
        inspectionForExporterStatus=inspectionForExporterStatusArray[0];
    }
    /// Inspector accepts inspection ///
    function acceptInspectionForExporter() public {
        require(equal(inspectionForExporterStatus,"Requested"),errMsg[0]);
        inspectionForExporterStatus=inspectionForExporterStatusArray[1];
        /// To do: inspectorForSeller = grab from frontend
    }

   /// Inspector for exporter inspects ///
    function certifyCertOfInspectionForExporter() public {
        require(equal(inspectionForExporterStatus,"Accepted") && msg.sender==inspectorForSeller,errMsg[0]);
        coiFromExporter.certified=true;
        coiFromExporter.signature=msg.sender;
       
       /// emit CertificationDone(coiFromExporter.certified,coiFromExporter.signature);
    }

    /// Exportor requests shipment ///
    function requestForShipment() public {
        require(msg.sender==exporter,errMsg[0]);
        shipmentStatus = shipmentStatusArray[0]; 
    }
    
    /// Shipper accepts shipment and assign exporter to bol holder///
    function acceptShipment() public {
        require(equal(shipmentStatus,"Pending Shipment") && msg.sender == shipper,errMsg[0]);
        shipmentStatus = shipmentStatusArray[1]; 
        bol.holder=exporter;  
        
    }

    /// After shipper ship out the goods, changes the goods status to "Ship out". ///
    function completeShipment() public{
        require(equal(shipmentStatus,"Ship out") && msg.sender == shipper,errMsg[0]);
        shipmentStatus = shipmentStatusArray[2];         
    }


    /// Inspector for importer inspects ///
    function certifyCertOfInspectionForImporter() public {

		require(msg.sender==inspectorForBuyer,errMsg[0]);
    
        coiFromImporter.certified=true;
        coiFromImporter.signature=msg.sender;
     ///   emit CertificationDone(coiFromImporter.certified,coiFromImporter.signature);
    }

    /// Importer makes payment
    function makePayment() public payable{
           
        if(importer!=msg.sender){
            revert(errMsg[0]);
        }
        if(boe.contractPrice!=msg.value){
            revert(errMsg[0]);
        }     
      
        /// pay exporter 93%
        boe.holder.transfer(SafeMath.div(SafeMath.mul(msg.value,93),100));
        /// pay inspectorForBuyer 1%
        inspectorForBuyer.transfer(SafeMath.div(SafeMath.mul(msg.value,1),100));
        /// pay inspectorForSeller 1%
        inspectorForSeller.transfer(SafeMath.div(SafeMath.mul(msg.value,1),100));
        /// pay shipper 1%
        shipper.transfer(SafeMath.div(SafeMath.mul(msg.value,1),100));
        /// pay issuing bank 2%
        issuingBank.transfer(SafeMath.div(SafeMath.mul(msg.value,2),100));
        /// To do: withdraw function 2% to smart contract
        bol.holder=msg.sender;
        shipmentStatus = shipmentStatusArray[3];  
        ///emit PaymentMade(msg.value, msg.sender);
    } 


    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    function equal(string _a, string _b) public pure returns (bool) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);

        return keccak256(a) == keccak256(b) ;
    }

}