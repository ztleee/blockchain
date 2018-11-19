pragma solidity ^0.4.24;
import "./SafeMath.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";//usage of library


contract Loan is Ownable {
    
    function retrieveRepaymentAmount() public pure returns  (uint256){}  
    function retrieveLoaningBank() public pure returns  (address){}
    
    
}


contract LetterOfCredit is Ownable  {
   
    using SafeMath for uint256;
    Loan loan;
    
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

    constructor(address _t) public {
        loan = Loan(_t);
    }

    function retrieveRepaymentAmount() public view returns  (uint256){
        
        return loan.retrieveRepaymentAmount();
    }  


    function retrieveLoaningBank() public view returns  (address){
        return loan.retrieveLoaningBank();
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
            contractPrice: contractPrice
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
    // function assignInspectionSeller() public {
    //     require(msg.sender==exporter,errMsg[0]);
        
    // }

    /// Exporter requests inspection ///
    function requestInspection(address sellerInspector) public {
        require(msg.sender==exporter,errMsg[0]);
        inspectionForExporterStatus=inspectionForExporterStatusArray[0];
        inspectorForSeller=sellerInspector;
    }

    /// Inspector accepts inspection ///
    function acceptInspectionForExporter() public {
        require(equal(inspectionForExporterStatus,"Requested")&&msg.sender==inspectorForSeller,errMsg[0]);
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
        require(equal(shipmentStatus,"In Port") && msg.sender == shipper,errMsg[0]);
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
        loan.retrieveLoaningBank().transfer(loan.retrieveRepaymentAmount());
        /// uint256 value = SafeMath.mul(msg.value, 1 ether); // Stores ether value as wei 
        uint256 value =  msg.value.sub(loan.retrieveRepaymentAmount());
        /// pay exporter 93%
        boe.holder.transfer((value.mul(93)).div(100));
        /// pay inspectorForBuyer 1%
        
        inspectorForBuyer.transfer((value.mul(1)).div(100));
        /// pay inspectorForSeller 1%
        inspectorForSeller.transfer((value.mul(1)).div(100));
        /// pay shipper 1%
        shipper.transfer((value.mul(1)).div(100));
        /// pay issuing bank 2%
        issuingBank.transfer((value.mul(2)).div(100));
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

    function getcontractPrice() public view returns (uint value){
        require(msg.sender==issuingBank);
        return boe.contractPrice;
    }

    function getExporter() public view returns (address holder){
        require(msg.sender==issuingBank);
        return exporter;
    }

    function getImporter() public view returns (address holder){
        require(msg.sender==issuingBank);
        return importer;
    }

    function getBOEHolder() public view returns (address holder){
        return boe.holder;
    }

    function getBOLHolder() public view returns (address holder){
        return bol.holder;
    }

    function getinspectorForSeller() public view returns (address holder){
        return inspectorForSeller;
    }

    function getissuingBank() public view returns (address holder){
        return issuingBank;
    }

    function getinspectorForBuyer() public view returns (address holder){
        return inspectorForBuyer;
    }

    function getInspectionForExporterStatus()public view returns (string) {
        return inspectionForExporterStatus;
    }

    function getInspectionForImporterStatus() public view returns (string)  {
        return inspectionForImporterStatus;
    }

    function getShipmentStatus() public view returns (string)  {
        return shipmentStatus;
    }

    function getcoiFromExporterCertified() public view returns (bool)  {
        return coiFromExporter.certified;
    }

    function getcoiFromExporterSignature() public view returns (address)  {
        return coiFromExporter.signature;
    }

    function getcoiFromImporterCertified() public view returns (bool)  {
        return coiFromImporter.certified;
    }

    function getcoiFromImporterSignature() public view returns (address)  {
        return coiFromImporter.signature;
    }







}