App = {
    web3Provider: null,
    contracts: {},

    init: function () {
        console.log("App started")
        return App.initWeb3();
    },

    initWeb3: function () {
        // Is there an injected web3 instance?
        if (typeof web3 !== 'undefined') {
            App.web3Provider = web3.currentProvider;
        } else {
            // If no injected web3 instance is detected, fall back to Ganache
            App.web3Provider = new Web3.providers.HttpProvider('http://localhost:8545');
        }
        web3 = new Web3(App.web3Provider);

        return App.initContract();
    },

    initContract: function () {
        $.getJSON('LetterOfCredit.json', function (data) {
            // Get the necessary contract artifact file and instantiate it with truffle-contract
            var LetterOfCreditArtifact = data;
            App.contracts.LetterOfCredit = TruffleContract(LetterOfCreditArtifact);

            // Set the provider for our contract
            App.contracts.LetterOfCredit.setProvider(App.web3Provider);
        });

        return App.bindEvents();
    },

    bindEvents: function () {
        $(document).on('click', '.btn-create', App.createBoe);
        $(document).on('click', '.btn-viewDetails', App.getDetails);
        $(document).on('click', '.btn-accept', App.issueLetterOfCredit);        
        $(document).on('click', '.btn-requestInspSeller', App.assignInspectionSeller);
        $(document).on('click', '.btn-acceptInspectSeller', App.acceptInspectSeller);
        $(document).on('click', '.btn-requestShipment', App.requestShipment);
        $(document).on('click', '.btn-acceptShipment', App.acceptShipment);
        $(document).on('click', '.btn-completeInspectSeller', App.completeInspectSeller);
        $(document).on('click', '.btn-completeShipment', App.completeShipment);
        $(document).on('click', '.btn-inspectorBuyerAkw', App.inspectorBuyerAkw);
        $(document).on('click', '.btn-collectAndPayment', App.collectAndPayment);
    },

    createBoe: function(event) {
        event.preventDefault();

        var LetterOfCreditInstance;
        var importer = document.getElementById("importer").value;
        var exporter = document.getElementById("exporter").value;
        var shipper = document.getElementById("shipper").value;
        var inspectorForExp=document.getElementById("insExporter").value;
        var issuingBank=document.getElementById("issuingBank").value;
        var shipmentValue = parseInt(document.getElementById("shipment").value);
        console.log("importer is " + importer)
        console.log("exporter is " + exporter)
        console.log("shipper is " + shipper)
        console.log("shipment value is " + shipmentValue)

        web3.eth.getAccounts(function (error, accounts) {
            if (error) {
                console.log(error);
            }

            App.contracts.LetterOfCredit.deployed().then(function (instance) {
                LetterOfCreditInstance = instance;
                return LetterOfCreditInstance.createBOE(exporter,importer,shipper,inspectorForExp,issuingBank,shipmentValue).then(function(){
                    document.getElementById("boeCreation").innerHTML = "Contract " + LetterOfCreditInstance.address + " successfully updated with value " + shipmentValue;
                    document.getElementById("boeCreatedDetails").innerHTML = "Importer: " + importer +"<br> Exporter: " + exporter + "<br> Shipper: " + shipper+ "<br> Issuing Bank: " + issuingBank +"<br> Inspector for Buyer" + inspectorForExp;
                });
            }).catch(function (err) {
                console.log(err);
            });
        });
    },

    getDetails: function(event) {
        event.preventDefault();

        var LetterOfCreditInstance;
        var address = document.getElementById("lcAdd").value;

        web3.eth.getAccounts(function (error, accounts) {
            if (error) {
                console.log(error);
            }

            App.contracts.LetterOfCredit.at(address).then(function (instance) {
                LetterOfCreditInstance = instance;
                LetterOfCreditInstance.getcontractPrice().then(function(result){
                    
                    document.getElementById("acceptLcConPrice").innerHTML = "Contract price: " + result.toNumber();
                });
                LetterOfCreditInstance.getExporter().then(function(result){
                    
                    document.getElementById("acceptLcExporter").innerHTML =  "Exporter: " + result;
                });
                LetterOfCreditInstance.getImporter().then(function(result){
                    LetterOfCreditInstance.getBOEHolder().then(function(result){
                        document.getElementById("currentBOE").innerHTML = "BOE holder: " + result;
                    });
                    
                    document.getElementById("acceptLcImporter").innerHTML =  "Importer: " + result;
                });
            }).catch(function (err) {
                document.getElementById("acceptLcConPrice").innerHTML=err.message;
            });
        });
    },

    issueLetterOfCredit:function(event){
        event.preventDefault();

        var LetterOfCreditInstance;
        var address = document.getElementById("lcAdd").value;

        web3.eth.getAccounts(function (error, accounts) {
            if (error) {
                console.log(error);
            }

            App.contracts.LetterOfCredit.at(address).then(function (instance) {
                LetterOfCreditInstance = instance;
                LetterOfCreditInstance.issueLetterOfCredit().then(function(){                    
                    LetterOfCreditInstance.getBOEHolder().then(function(result){
                        document.getElementById("acceptStatus").innerHTML = "Letter of Credit is issued"+ "\n"+ "BOE holder: " + result;
                    });                   
                });
            }).catch(function (err) {
                console.log(err.message);
            });
        });
    },

    assignInspectionSeller:function(event){
        event.preventDefault();

        var LetterOfCreditInstance;
        var address = document.getElementById("lcAdd1").value;
        var inspaddress = document.getElementById("inspSeller").value;

        web3.eth.getAccounts(function (error, accounts) {
            if (error) {
                console.log(error);
            }

            App.contracts.LetterOfCredit.at(address).then(function (instance) {
                LetterOfCreditInstance = instance;
                LetterOfCreditInstance.assignInspectionSeller(inspaddress).then(function(){                    
                    LetterOfCreditInstance.getinspectorForSeller().then(function(result){
                        document.getElementById("assignInspSeller").innerHTML = "Inspector for Seller: " + result;
                        LetterOfCreditInstance.requestInspection().then(function(){                    
                            LetterOfCreditInstance.getInspectionForExporterStatus().then(function(result){
                                document.getElementById("inspectionStatusSeller").innerHTML = "Inspection Status: " + result;
                            });                   
                        });
                    });                   
                });
                
            }).catch(function (err) {
                console.log(err.message);
            });
        });
    },

    acceptInspectSeller:function(event){
        event.preventDefault();

        var LetterOfCreditInstance;
        var address = document.getElementById("lcAdd2").value;

        web3.eth.getAccounts(function (error, accounts) {
            if (error) {
                console.log(error);
            }

            App.contracts.LetterOfCredit.at(address).then(function (instance) {
                LetterOfCreditInstance = instance;
                LetterOfCreditInstance.acceptInspectionForExporter().then(function(){                    
                    LetterOfCreditInstance.getInspectionForExporterStatus().then(function(result){
                        document.getElementById("sellerInspectStatus").innerHTML = "Inspection Status: " + result;
                    });                   
                });
                
            }).catch(function (err) {
                console.log(err.message);
            });
        });
    },

    completeInspectSeller:function(event){
        event.preventDefault();

        var LetterOfCreditInstance;
        var address = document.getElementById("lcAdd5").value;

        web3.eth.getAccounts(function (error, accounts) {
            if (error) {
                console.log(error);
            }

            App.contracts.LetterOfCredit.at(address).then(function (instance) {
                LetterOfCreditInstance = instance;
                LetterOfCreditInstance.certifyCertOfInspectionForExporter().then(function(){                    
                    LetterOfCreditInstance.getcoiFromExporterCertified().then(function(result){
                        LetterOfCreditInstance.getcoiFromExporterSignature().then(function(result1){
                            document.getElementById("completeInspectSellerP").innerHTML = "Certificate of Inspection signed?: " + result+  "Signature of Certificate of Inspection (Seller): " + result1;
                           
                        }); 
                    });                   
                });
                
            }).catch(function (err) {
                console.log(err.message);
            });
        });
    },

    requestShipment:function(event){
        event.preventDefault();

        var LetterOfCreditInstance;
        var address = document.getElementById("lcAdd3").value;

        web3.eth.getAccounts(function (error, accounts) {
            if (error) {
                console.log(error);
            }

            App.contracts.LetterOfCredit.at(address).then(function (instance) {
                LetterOfCreditInstance = instance;
                LetterOfCreditInstance.requestForShipment().then(function(){                    
                    LetterOfCreditInstance.getShipmentStatus().then(function(result){
                        document.getElementById("requestShipment").innerHTML = "Shipment Status: " + result;
                    });                   
                });
                
            }).catch(function (err) {
                console.log(err.message);
            });
        });
    },

    acceptShipment:function(event){
        event.preventDefault();

        var LetterOfCreditInstance;
        var address = document.getElementById("lcAdd4").value;

        web3.eth.getAccounts(function (error, accounts) {
            if (error) {
                console.log(error);
            }

            App.contracts.LetterOfCredit.at(address).then(function (instance) {
                LetterOfCreditInstance = instance;
                LetterOfCreditInstance.acceptShipment().then(function(){                    
                    LetterOfCreditInstance.getShipmentStatus().then(function(result){
                        document.getElementById("shipperShipStatus").innerHTML = "Shipment Status: " + result;
                        LetterOfCreditInstance.getBOLHolder().then(function(result1){
                            document.getElementById("bolHolderAccept").innerHTML = "Current Bill of Lading Holder: " + result1;
                        }); 
                    });                   
                });
                
            }).catch(function (err) {
                console.log(err.message);
            });
        });
    },

    completeShipment:function(event){
        event.preventDefault();

        var LetterOfCreditInstance;
        var address = document.getElementById("lcAdd6").value;

        web3.eth.getAccounts(function (error, accounts) {
            if (error) {
                console.log(error);
            }

            App.contracts.LetterOfCredit.at(address).then(function (instance) {
                LetterOfCreditInstance = instance;
                LetterOfCreditInstance.completeShipment().then(function(){                    
                    LetterOfCreditInstance.getShipmentStatus().then(function(result){
                        document.getElementById("shipperShipStatusComplete").innerHTML = "Shipment Status: " + result; 
                    });                   
                });
                
            }).catch(function (err) {
                console.log(err.message);
            });
        });
    },

    inspectorBuyerAkw:function(event){
        event.preventDefault();

        var LetterOfCreditInstance;
        var address = document.getElementById("lcAdd7").value;

        web3.eth.getAccounts(function (error, accounts) {
            if (error) {
                console.log(error);
            }

            App.contracts.LetterOfCredit.at(address).then(function (instance) {
                LetterOfCreditInstance = instance;
                LetterOfCreditInstance.certifyCertOfInspectionForImporter().then(function(){                    
                    LetterOfCreditInstance.getcoiFromImporterCertified().then(function(result){
                        document.getElementById("inspectionBuyerCoi").innerHTML = "COI certified? : " + result; 
                        LetterOfCreditInstance.getcoiFromImporterSignature().then(function(result){
                            document.getElementById("inspectionBuyerCoiSig").innerHTML = "COI Signature: " + result; 
                        });
                    });                   
                });
                
            }).catch(function (err) {
                console.log(err.message);
            });
        });
    },

    collectAndPayment:function(event){
        event.preventDefault();

        var LetterOfCreditInstance;
        var address = document.getElementById("lcAdd8").value;

        web3.eth.getAccounts(function (error, accounts) {
            if (error) {
                console.log(error);
            }

            App.contracts.LetterOfCredit.at(address).then(function (instance) {
                LetterOfCreditInstance = instance;
                LetterOfCreditInstance.makePayment().then(function(){                    
                    LetterOfCreditInstance.getBOLHolder().then(function(result){
                        document.getElementById("bolOwnerCollect").innerHTML = "BOL current Owner : " + result; 
                        LetterOfCreditInstance.getShipmentStatus().then(function(result){
                            document.getElementById("bolStatusCollect").innerHTML = "Shipment Status: " + result; 
                        });
                    });                   
                });
                
            }).catch(function (err) {
                console.log(err.message);
            });
        });
    },

};

$(function () {
    $(window).load(function () {
        App.init();
    });
});
