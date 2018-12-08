var TicTacToeContract = artifacts.require("./TicTacToeContract.sol");

module.exports = function(deployer) {
  deployer.deploy(TicTacToeContract);
};
