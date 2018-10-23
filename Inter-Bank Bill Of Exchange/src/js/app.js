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
        $(document).on('click', '.btn-set', App.setBOE);
        $(document).on('click', '.btn-exercise', App.exerciseBOE);
        $(document).on('click', '.btn-auction', App.auction);
        $(document).on('click', '.btn-auctionEnd', App.auctionEnd);
        $(document).on('click', 'btn-ship', App.setShip);
        $(document).on('click', '.btn-cert', App.certify);
        $(document).on('click','.btn-details',App.getDetails);
        $(document).on('click','.btn-stop',App.stop);
        $(document).on('click','.btn-start',App.start);
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
                    document.getElementById("boeCreatedDetails").innerHTML = "Importer: " + importer +"<br> Exporter: " + exporter + "<br> Shipper: " + shipper+ "<br> Issuing Bank: " + issuingBank;
                });
            }).catch(function (err) {
                console.log(err);
            });
        });
    },
};

$(function () {
    $(window).load(function () {
        App.init();
    });
});
