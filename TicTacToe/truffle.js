var HDWalletProvider = require("truffle-hdwallet-provider");

// TODO enter your mnemonic here
var mnemonic = "";

module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // for more about customizing your Truffle configuration!
  networks: {
    development: {
      host: "127.0.0.1",
      port: 7545,
      network_id: "*" // Match any network id
    },
 ropsten: {
      provider: function() {
        return new HDWalletProvider(mnemonic, "https://ropsten.infura.io/2f132116f0134e12933aacbb37341012");
      },
      network_id: 3,
      gasPrice: 20000000000,
      gas: 3716887
    },
    rinkeby: {
      provider: function() {
        return new HDWalletProvider(mnemonic, "https://rinkeby.infura.io/2f132116f0134e12933aacbb37341012");
      },
      network_id: 4,
      gasPrice: 20000000000,
      gas: 3716887
    },
    kovan: {
      provider: function() {
        return new HDWalletProvider(mnemonic, "https://kovan.infura.io/2f132116f0134e12933aacbb37341012");
      },
      network_id: 42,
      gasPrice: 20000000000,
      gas: 3716887
    },
    main: {
      provider: function() {
        return new HDWalletProvider(mnemonic, "https://mainnet.infura.io/2f132116f0134e12933aacbb37341012");
      },
      network_id: 1,
      gasPrice: 20000000000, // 20 GWEI
      gas: 3716887    // gas limit, set any number you want
    }
  }
};
