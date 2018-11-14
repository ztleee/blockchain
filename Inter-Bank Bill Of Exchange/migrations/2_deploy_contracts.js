var LetterOfCredit = artifacts.require("LetterOfCredit");
var Loan = artifacts.require("Loan");


module.exports = function(deployer) {
  deployer.deploy(Loan).then(function() {
    return deployer.deploy(LetterOfCredit, Loan.address)
  });
};
