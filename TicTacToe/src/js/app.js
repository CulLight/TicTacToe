// this is using web3 v0.20.3
// api can be found here
// https://github.com/ethereum/wiki/wiki/JavaScript-API

App = {
   web3Provider: null,
   contracts: {},
   account: '0x0',

   init: function() {
      return App.initWeb3();
   },

   initWeb3: function() {
      if (typeof web3 !== 'undefined') {
         // If a web3 instance is already provided by Meta Mask.
         App.web3Provider = web3.currentProvider;
         web3 = new Web3(web3.currentProvider);
      } else {
         // Specify default instance if no web3 instance provided
         App.web3Provider = new Web3.providers.HttpProvider('http://localhost:7545');
         web3 = new Web3(App.web3Provider);
      }
      return App.initContract();
   },

   initContract: function() {
      $.getJSON("TicTacToeContract.json", function(ticTacToeContract) {
         // Instantiate a new truffle contract from the artifact
         App.contracts.TicTacToeContract = TruffleContract(ticTacToeContract);
         // Connect provider to interact with contract
         App.contracts.TicTacToeContract.setProvider(App.web3Provider);

         App.listenForEvents();

         return App.render();
      });
   },

   // Listen for events emitted from the contract
   listenForEvents: function() {
      App.contracts.TicTacToeContract.deployed().then(function(instance) {
         // Restart Chrome if you are unable to receive this event
         // This is a known issue with Metamask
         // https://github.com/MetaMask/metamask-extension/issues/2393

         instance.betMadeEvent({}, {
            fromBlock: 'latest',
            toBlock: 'latest'
         }).watch(function(error, event) {
            console.log("Bet made event", event)
            // Reload when a new vote is recorded
            App.render();
         });

         instance.roundEndedEvent({}, {
            fromBlock: 'latest',
            toBlock: 'latest'
         }).watch(function(error, event) {
            console.log("Round ended event", event)
            App.render();
         });

         instance.FaucetUsedEvent({}, {
            fromBlock: 'latest',
            toBlock: 'latest'
         }).watch(function(error, event) {
            console.log("Faucet fill, used or ended event", event)
            App.render();
         });

      });
   },

   render: function() {
      var ticTacToeContractInstance;
      var content = $("#content");


      // Display account details
      web3.eth.getCoinbase(function(err, account) {
         if (err === null) {
            App.account = account;
            $("#accountAddress").html("Your Account: " + account);
            web3.eth.getBalance(account, function(err, balance) {
               if (err === null) {
                  $("#accountBalance").html("Your Balance: " + web3.fromWei(balance, 'ether') + " Ether");
               }
            });
         }
      });
      // Display Contract Address
      App.contracts.TicTacToeContract.deployed().then(function(instance) {
         ticTacToeContractInstance = instance;
         $("#contractAddress").html("Contract Address: " + ticTacToeContractInstance.address);
      })

      // Display Owner Address
      App.contracts.TicTacToeContract.deployed().then(function(instance) {
         ticTacToeContractInstance = instance;
         ticTacToeContractInstance.owner().then(function(_owner){
               $("#ownerAddress").html("Owner Address: " + _owner);
         });
      })

      // Display Pot
      App.contracts.TicTacToeContract.deployed().then(function(instance) {
         ticTacToeContractInstance = instance;
         ticTacToeContractInstance.getPot().then(function(potArray){
               // totalPot (totalPot - stake of owner)
               totPot = web3.fromWei(potArray[0], 'ether').toNumber();
               netPot = web3.fromWei(potArray[1], 'ether').toNumber();
               $("#pot").html("Pot: " + totPot + " (" + netPot + ") ETH");
         });
      })

      // Display Team Turn
      App.contracts.TicTacToeContract.deployed().then(function(instance) {
         ticTacToeContractInstance = instance;
         ticTacToeContractInstance.getActiveTeam().then(function(activeTeam){
               if (activeTeam.toNumber() == 1) {
                  $("#teamTurn").html("It is your turn, Team A");
               } else {
                  $("#teamTurn").html("It is your turn, Team B");
               }
         });
      })

      App.contracts.TicTacToeContract.deployed().then(function(instance) {
         ticTacToeContractInstance = instance;
         ticTacToeContractInstance.currentRound().then(function(round){
               $("#round").html("Round: " + round.toNumber());
         });
      })

      // Load fields with content
      App.contracts.TicTacToeContract.deployed().then(function(instance) {
         ticTacToeContractInstance = instance;
         var fieldUnplayedColor = "#F0F0F0";
         var fontUnplayedColor = '#a4a4a4';
         var betColor = 'black';
         var fieldTeamAColor = '#b4575c';
         var fontTeamAColor = 'white';
         var fieldTeamBColor = '#578bb4';
         var fontTeamBColor = 'white';
         for (var i = 1; i < 10; i++) {
            ticTacToeContractInstance.getBoardInfo(i).then(function(field) {
               var id = field[0].toNumber();
               // 0 = unplayed
               // 1 = Team A
               // 4 = Team B
               var status = field[1].toNumber();
               var numBets = field[2].toNumber();
               var amountBet = web3.fromWei(field[3], 'ether').toNumber();

               if (status == 0) {
                  // field not yet played
                  $('#cell_' + id).css('background', fieldUnplayedColor);
                  if (numBets == 0) {
                     $('#cell_' + id).css('color', fontUnplayedColor);
                  } else {
                     $('#cell_' + id).css('color', betColor);
                  }
                  $('#cell_' + id).html("Cell: " + id + "<br/>#bets: " + numBets + "<br/>#ETH: " + amountBet);
               } else if (status == 1) {
                  // Team A
                  $('#cell_' + id).css('background', fieldTeamAColor);
                  $('#cell_' + id).css('color', fontTeamAColor);
                  $('#cell_' + id).html("Cell: " + id + "<br/>#bets: " + numBets + "<br/>#ETH: " + amountBet);
               } else if (status == 4) {
                  // Team A
                  $('#cell_' + id).css('background', fieldTeamBColor);
                  $('#cell_' + id).css('color', fontTeamBColor);
                  $('#cell_' + id).html("Cell: " + id + "<br/>#bets: " + numBets + "<br/>#ETH: " + amountBet);
               }
            }).catch(function(error) {
               console.warn(error);
            });
         }
      }).catch(function(error) {
         console.warn(error);
      });

      // Load player Team A
      App.contracts.TicTacToeContract.deployed().then(function(instance) {
         ticTacToeContractInstance = instance;
         return ticTacToeContractInstance.getTeamInfo(1);
      }).then(function(teamA) {
         var TeamAplayers = $("#TeamAplayers");
         TeamAplayers.empty();

         var numPlayersTeamA = teamA[2].toNumber();

         for (var i = 1; i <= numPlayersTeamA; i++) {
            ticTacToeContractInstance.getPlayerInfoById(1,i).then(function(player) {
               var id = player[0].toNumber();
               var playerAddress = player[1];
               var numBets = player[3].toNumber();
               var amountBet = web3.fromWei(player[4], 'ether').toNumber();

               var betTemplate = "<tr id='tabA_"+id+"' align='center' color='white'><td>" + playerAddress + "</td><td>" + numBets + "</td><td>" + amountBet + "</td></tr>"
               // avoid multiple filling of table
               if ($('#tabA_'+id).length < 1 && id!=0) {
                  TeamAplayers.append(betTemplate);
               }
            }).catch(function(error) {
               console.warn(error);
            });
         }
      }).catch(function(error) {
         console.warn(error);
      });

      // Load player Team B
      App.contracts.TicTacToeContract.deployed().then(function(instance) {
         ticTacToeContractInstance = instance;
         return ticTacToeContractInstance.getTeamInfo(2);
      }).then(function(teamB) {
         var TeamBplayers = $("#TeamBplayers");
         TeamBplayers.empty();

         var numPlayersTeamB = teamB[2].toNumber();

         for (var i = 1; i <= numPlayersTeamB; i++) {
            ticTacToeContractInstance.getPlayerInfoById(2,i).then(function(player) {
               var id = player[0].toNumber();
               var playerAddress = player[1];
               var numBets = player[3].toNumber();
               var amountBet = web3.fromWei(player[4], 'ether').toNumber();

               var betTemplate = "<tr id='tabB_"+id+"' align='center' color='white'><td>" + playerAddress + "</td><td>" + numBets + "</td><td>" + amountBet + "</td></tr>"
               // avoid multiple filling of table
               if ($('#tabB_'+id).length < 1 && id!=0) {
                  TeamBplayers.append(betTemplate);
               }
            }).catch(function(error) {
               console.warn(error);
            });
         }
      }).catch(function(error) {
         console.warn(error);
      });

   },


   endRoundApp: function() {
     App.contracts.TicTacToeContract.deployed().then(function(instance) {
      return instance.endRound({ from: App.account });
     }).then(function(result) {
     }).catch(function(err) {
      console.error(err);
     });
   }
};

$(function() {
   $(window).load(function() {
      App.init();
   });
});
