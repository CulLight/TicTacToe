pragma solidity ^0.4.24;

contract TicTacToeContract {

    // --------------------------------------
    // state variables
    // --------------------------------------

   enum Status { FAUCET, RUNNING, TEAM_A_WON, TEAM_B_WON, DRAW}
   Status public status;

    // uint can be 1 (Team A) or 2 (Team B)
    mapping (uint => Team) Teams;
    struct Team {
        uint id; // 1 or 2
        uint numBetsCurrentRound;
        uint amountBetCurrentRound;
        uint totalAmountBet;
        uint totalNumPlayers;
        mapping (address => Player) players;
        // 'playersAddress' is needed access players in payout function
		mapping (uint => address) playersAddress;
        bool nextBet; // bool if it is the turn of this team
    }

    struct Player {
		uint id;
        uint totalAmountBet;
        uint totalNumMovesBet;
        uint lastBetRound; // round in which player bet the last time
		address playerAddress;
        bool isTeamA;
    }

    // field's id of board
    // uint from 1 to 9
    //   1 |  2  |  3
    //   4 |  5  |  6
    //   7 |  8  |  9
    // todo: initialize board in constructor
    mapping (uint => Field) board;
    struct Field {
        uint id;
        // 0 = default = unplayed; 1 = TeamA; 4 = TeamB
        uint unplayedOrAorB;
        // the field with the most amount bet on it will be chosen.
        // we will take record of the number of bets on one field
        uint numBets;
        // and the amount of ether bet on it
        uint amountBet;
    }

    uint public currentRound;
    uint startTimeOfCurrentRound;

    bool betMade;

    address public owner;

    // share of pot that goes to owner of contract in % (need to be integer)
    uint shareOwner = 10;

    uint public constant minStake = 0.1 ether;

    // mapping to see who used the faucet
    mapping (address => bool) usedFaucet;
    // ether every person gets
    uint faucetMoney = 1.5 ether;




    // --------------------------------------
    // events
    // --------------------------------------

    event betMadeEvent();
    event roundEndedEvent();
    event FaucetUsedEvent();




    // --------------------------------------
    // modifiers
    // --------------------------------------

    // nur Owner
    modifier onlyOwner () {
        require(msg.sender == owner);
        _;
    }

    // nur Owner
    modifier notOwner () {
        require(msg.sender != owner);
        _;
    }

    modifier inStatus (Status _status) {
       require(status == _status);
       _;
    }

    modifier activeTeam (uint _Teamid) {
        require(Teams[_Teamid].nextBet == true);
        _;
    }

    modifier activeTeamA () {
        require(Teams[1].nextBet == true);
        _;
    }

    modifier activeTeamB () {
        require(Teams[2].nextBet == true);
        _;
    }

    // man kann nur in einem Team wetten
    modifier notAlreadyPlayerTeamB() {
        require(Teams[2].players[msg.sender].playerAddress == address(0));
        _;
    }

    modifier notAlreadyPlayerTeamA() {
        require(Teams[1].players[msg.sender].playerAddress == address(0));
        _;
    }

    modifier isValidField(uint _fieldId) {
        require (_fieldId > 0 && _fieldId < 10 );
        _;
    }

    // assure that field is free
    modifier unplayedField(uint _fieldId) {
        require(board[_fieldId].unplayedOrAorB == 0);
        _;
    }

    modifier hasNotBetYetCurrentRound() {
        require(Teams[1].players[msg.sender].lastBetRound < currentRound);
        require(Teams[2].players[msg.sender].lastBetRound < currentRound);
        _;
    }

    modifier validStake() {
        require(msg.value >= minStake);
        _;
    }

    modifier hasBetBeenMade() {
      require(betMade == true);
      _;
   }




    // --------------------------------------
    // functions
    // --------------------------------------

    constructor () {
        owner = msg.sender;
        startTheGame();
    }

    // initialize 'board' and Teams
    function startTheGame () private {
        status = Status.FAUCET;
        // create Team A
        uint teamAid = 1;
        Team newTeamA = Teams[teamAid];
        newTeamA.id = teamAid;
        newTeamA.nextBet = true;

        // create Team B
        uint teamBid = 2;
        Team newTeamB = Teams[teamBid];
        newTeamB.id = teamBid;
        newTeamB.nextBet = false;

        // initialize board
        for (uint i=1; i<10; i++) {
           Field field = board[i];
           field.id = i;
           field.unplayedOrAorB = 0;
           field.numBets = 0;
           field.amountBet = 0;
       }

        currentRound = 1;
        startTimeOfCurrentRound = now;
    }

    // fallback function to fill faucet
   function () public payable {}

   // in 'Write Contract' tab of etherscan the fallback function is not shown.
   // Make explicit fallback function to fill faucet with Ether
   function fillFaucet() public payable {
      emit FaucetUsedEvent();
   }

   function getBalance () public view returns (uint balance) {
       return this.balance;
   }

    function useFaucet () public inStatus(Status.FAUCET) {
      // faucet can only be used once
      require(usedFaucet[msg.sender] == false && this.balance >= faucetMoney);
      // msg sender has not yet used faucet
      usedFaucet[msg.sender] = true; // msg.sender can not use faucet again
      msg.sender.transfer(faucetMoney);
      emit FaucetUsedEvent();
   }

   function endFaucet () public onlyOwner inStatus(Status.FAUCET) {
      owner.transfer(this.balance);
      status = Status.RUNNING;
      emit FaucetUsedEvent();
   }

    // new players or player from team A can bet on next field '_betField' (1-9)
    function newBetForTeamA (uint _betField) public payable
    notAlreadyPlayerTeamB()
    notOwner()
    activeTeamA()
    isValidField(_betField)
    unplayedField(_betField)
    hasNotBetYetCurrentRound()
    validStake()
    inStatus(Status.RUNNING)
    {
        Player player = Teams[1].players[msg.sender];
        // add new player to team A
        if (player.playerAddress == address(0)){
            uint newID = ++Teams[1].totalNumPlayers;
            Teams[1].playersAddress[newID] = msg.sender;
            player.id = newID;
            player.playerAddress = msg.sender;
            // todo: no need to set this every time
            player.isTeamA = true;
        }

        Field betField = board[_betField];
        betField.numBets++;
        betField.amountBet += msg.value;

        Teams[1].numBetsCurrentRound++;
        Teams[1].amountBetCurrentRound += msg.value;

        player.totalAmountBet += msg.value;
        player.totalNumMovesBet++;
        player.lastBetRound = currentRound;

        betMade = true;

        emit betMadeEvent();
    }

    // new players or player from team B can bet on next field '_betField' (1-9)
    function newBetForTeamB (uint _betField) public payable
    notAlreadyPlayerTeamA()
    notOwner()
    activeTeamB()
    isValidField(_betField)
    unplayedField(_betField)
    hasNotBetYetCurrentRound()
    validStake()
    inStatus(Status.RUNNING)
    {
        Player player = Teams[2].players[msg.sender];
        // add new player to team A
        if (player.playerAddress == address(0)){
            uint newID = ++Teams[2].totalNumPlayers;
            Teams[2].playersAddress[newID] = msg.sender;
            player.id = newID;
            player.playerAddress = msg.sender;
            // todo: no need to set this every time
            player.isTeamA = false;
        }

        Field betField = board[_betField];
        betField.numBets++;
        betField.amountBet += msg.value;

        Teams[2].numBetsCurrentRound++;
        Teams[2].amountBetCurrentRound += msg.value;

        player.totalAmountBet += msg.value;
        player.totalNumMovesBet++;
        player.lastBetRound = currentRound;

        betMade = true;

        emit betMadeEvent();
    }

    function endRound () onlyOwner inStatus(Status.RUNNING) hasBetBeenMade() {
        // get active team
        // 1 = Team A
        // 2 = Team B
        uint activeTeam = getActiveTeam();

        Teams[activeTeam].totalAmountBet += Teams[activeTeam].amountBetCurrentRound;
        Teams[activeTeam].numBetsCurrentRound = 0; // todo looks like this variabel is not used
        Teams[activeTeam].amountBetCurrentRound = 0;


        uint winningFieldIndex = getWinningFieldIndex();
        Field winningField = board[winningFieldIndex];

        if (activeTeam == 1){
            // Team A
            winningField.unplayedOrAorB = 1;
            Teams[1].nextBet = false;
            Teams[2].nextBet = true;
        }
        else if (activeTeam == 2){
            // Team B
            winningField.unplayedOrAorB = 4;
            Teams[1].nextBet = true;
            Teams[2].nextBet = false;
        }

        // check for winner but only after 5 rounds
        if (currentRound >= 5){
            // check involves all rows (3x), all coulmns (3x) and diagonals (2x)
            // unplayedOrAorB: 1 = TeamA; 4 = TeamB
            // board:
            //   1 |  2  |  3
            //   4 |  5  |  6
            //   7 |  8  |  9
            if (
            // rows
            board[1].unplayedOrAorB+board[2].unplayedOrAorB+board[3].unplayedOrAorB == 3 ||
            board[4].unplayedOrAorB+board[5].unplayedOrAorB+board[6].unplayedOrAorB == 3 ||
            board[7].unplayedOrAorB+board[8].unplayedOrAorB+board[9].unplayedOrAorB == 3 ||
            // columns
            board[1].unplayedOrAorB+board[4].unplayedOrAorB+board[7].unplayedOrAorB == 3 ||
            board[2].unplayedOrAorB+board[5].unplayedOrAorB+board[8].unplayedOrAorB == 3 ||
            board[3].unplayedOrAorB+board[6].unplayedOrAorB+board[9].unplayedOrAorB == 3 ||
            // diagonals
            board[1].unplayedOrAorB+board[5].unplayedOrAorB+board[9].unplayedOrAorB == 3 ||
            board[3].unplayedOrAorB+board[5].unplayedOrAorB+board[7].unplayedOrAorB == 3)
            {
                status = Status.TEAM_A_WON;
                payoutMoney();
            } else if (
            // rows
            board[1].unplayedOrAorB+board[2].unplayedOrAorB+board[3].unplayedOrAorB == 12 ||
            board[4].unplayedOrAorB+board[5].unplayedOrAorB+board[6].unplayedOrAorB == 12 ||
            board[7].unplayedOrAorB+board[8].unplayedOrAorB+board[9].unplayedOrAorB == 12 ||
            // columns
            board[1].unplayedOrAorB+board[4].unplayedOrAorB+board[7].unplayedOrAorB == 12 ||
            board[2].unplayedOrAorB+board[5].unplayedOrAorB+board[8].unplayedOrAorB == 12 ||
            board[3].unplayedOrAorB+board[6].unplayedOrAorB+board[9].unplayedOrAorB == 12 ||
            // diagonals
            board[1].unplayedOrAorB+board[5].unplayedOrAorB+board[9].unplayedOrAorB == 12 ||
            board[3].unplayedOrAorB+board[5].unplayedOrAorB+board[7].unplayedOrAorB == 12)
            {
                status = Status.TEAM_B_WON;
                payoutMoney();
            } else if (status == Status.RUNNING && currentRound == 9) {
                // check for draw
                status = Status.DRAW;
                payoutMoney();
            }
        }

        // for all unplayed fields, clear bets
        for (uint i=1; i<10; i++) {
            Field field = board[i];
            if (field.unplayedOrAorB == 0 && field.numBets > 0) {
                field.numBets = 0;
                field.amountBet = 0;
            }
        }

       currentRound++;
       startTimeOfCurrentRound = now;

       betMade = false;

       emit roundEndedEvent();
    }

    function payoutMoney() private {
        uint pot = Teams[1].totalAmountBet + Teams[2].totalAmountBet;

        // part of pot goes to contract owner
        owner.transfer(this.balance*shareOwner/100);

        uint leftOverPot = this.balance;

        if (status == Status.DRAW) {
            // Team A
            for (uint i=1; i<=Teams[1].totalNumPlayers; i++) {
                address playerAddress = Teams[1].playersAddress[i];
                uint amountBet = Teams[1].players[playerAddress].totalAmountBet;
                // share: leftOverPot * amountBet/pot
                playerAddress.transfer(leftOverPot * amountBet/pot);
            }
            // Team B
            for (i=1; i<=Teams[2].totalNumPlayers; i++) {
                playerAddress = Teams[2].playersAddress[i];
                amountBet = Teams[2].players[playerAddress].totalAmountBet;
                // share: leftOverPot * amountBet/pot
                playerAddress.transfer(leftOverPot * amountBet/pot);
            }
        } else if (status == Status.TEAM_A_WON) {
            for (i=1; i<=Teams[1].totalNumPlayers; i++) {
                playerAddress = Teams[1].playersAddress[i];
                amountBet = Teams[1].players[playerAddress].totalAmountBet;
                // share: leftOverPot * amountBet/Team[1].totalAmountBet
                playerAddress.transfer(leftOverPot * amountBet/Teams[1].totalAmountBet);
            }
        } else if (status == Status.TEAM_B_WON) {
            for (i=1; i<=Teams[2].totalNumPlayers; i++) {
                playerAddress = Teams[2].playersAddress[i];
                amountBet = Teams[2].players[playerAddress].totalAmountBet;
                // share: leftOverPot * amountBet/Team[2].totalAmountBet
                playerAddress.transfer(leftOverPot * amountBet/Teams[2].totalAmountBet);
            }
        }
    }

    function getActiveTeam() public view returns (uint _activeTeam) {
        // 1 = A (for odd rounds)
        // 2 = B (for even rounds)
        if (currentRound%2 == 1){
            _activeTeam = 1;
        } else {
            _activeTeam = 2;
        }
        return _activeTeam;
    }

    function getWinningFieldIndex() public view returns (uint _winningFieldIndex) {

        uint highestAmountBet = 0;
        // loop through all fields
        for (uint i=1; i<10; i++) {
            if (board[i].unplayedOrAorB == 0) {
                // only check field if it is not played yet
               uint amountBet = board[i].amountBet;
               // if amountBet is higher, make this field the winningField
               if (amountBet > highestAmountBet) {
                   _winningFieldIndex = i;
                   highestAmountBet = amountBet;
               }
            }
       }
       return _winningFieldIndex;
    }

    function getPot() public view returns (uint totaltPot, uint totallPot) {
        return (this.balance, this.balance - this.balance*shareOwner/100);
    }

    // call function
    function getTeamInfo (uint _Teamid) view public returns
    (uint numBetsCurrentRound, uint amountBetCurrentRound, uint totalNumPlayers, uint totalAmountBet, bool nextBet) {
        return (Teams[_Teamid].numBetsCurrentRound, Teams[_Teamid].amountBetCurrentRound, Teams[_Teamid].totalNumPlayers, Teams[_Teamid].totalAmountBet, Teams[_Teamid].nextBet);
    }

    // call function
    function getPlayerInfoByAddress(uint _Teamid, address _playerAddress) view public returns
    (address playerAddress, bool isTeamA, uint totalNumMovesBet, uint totalAmountBet, uint lastBetRound) {
        Team team = Teams[_Teamid];
        Player memory player = team.players[_playerAddress];
        return (player.playerAddress, player.isTeamA, player.totalNumMovesBet, player.totalAmountBet, player.lastBetRound);
    }

    // function getPlayerInfoById(uint _Teamid, uint _id) view public returns
    // (address playerAddress, bool isTeamA, uint totalNumMovesBet, uint totalAmountBet, uint lastBetRound) {
    //     Team team = Teams[_Teamid];
    //     address _playerAddress = team.playersAddress[_id];
    //     Player memory player = team.players[_playerAddress];
    //     return (player.playerAddress, player.isTeamA, player.totalNumMovesBet, player.totalAmountBet, player.lastBetRound);
    // }
    function getPlayerInfoById(uint _Teamid, uint _id) view public returns
    (uint id, address playerAddress, bool isTeamA, uint totalNumMovesBet, uint totalAmountBet, uint lastBetRound) {
         Team team = Teams[_Teamid];
         address _playerAddress = team.playersAddress[_id];
         Player memory player = team.players[_playerAddress];
         return (player.id, player.playerAddress, player.isTeamA, player.totalNumMovesBet, player.totalAmountBet, player.lastBetRound);
     }

    // call function, da bei getTeamInfo bereits zu viele Parameter
    function getWinner () view public returns (uint winningTeamIndex) {
        require (status == Status.TEAM_A_WON || status == Status.TEAM_B_WON);
        if (status == Status.TEAM_A_WON) {
            winningTeamIndex = 1;
        } else if (status == Status.TEAM_A_WON) {
            winningTeamIndex = 2;
        }
        return winningTeamIndex;
    }

    // call function
    function getBoardInfo(uint _fieldId) view public returns (uint id, uint unplayedOrAorB, uint numBets, uint amountBet) {
        return (board[_fieldId].id, board[_fieldId].unplayedOrAorB, board[_fieldId].numBets, board[_fieldId].amountBet);
    }

    function getTimeOfCurrentRound() public view returns (uint elapsedTime) {
        return (now-startTimeOfCurrentRound);
    }
    // call function Zeit in Sekunden anzeigen seit 1970 (Hilfsfunktion) kann man evtl später für Zeitanzeige verwenden
    function getToday ()  view public returns (uint _today) {
        _today = now;
    }
}
