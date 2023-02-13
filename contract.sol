// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts@4.8.1/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts@4.8.1/security/Pausable.sol";
import "@openzeppelin/contracts@4.8.1/access/Ownable.sol";

contract Lottery is ERC721, Pausable, Ownable {
    struct lotteryStruct {
        uint256 startTime;
        uint256 endTime;
        bool isActive; 
        bool isCompleted; 
        uint price;
    }

    

    uint public ticketPrice;
    uint public maxParticipants;
    uint public NumberOfPlayers;
    address public oracle;
    uint public NumberOfWinners;
    uint public individualPrice;

    lotteryStruct public lotterydetails;


     mapping(address => uint) public ticketOwner;
     mapping(address => bool) public hasPlayed;
     mapping(address => bool) public isWinner;



    function purchaseTicket (uint[] memory _tickets) public{
        require(block.timestamp > lotterydetails.startTime, "lottery not started!");
        require(block.timestamp < lotterydetails.endTime, "lottery is ended");
        require(lotterydetails.isActive == true, "lottery not active");
        require (!lotterydetails.isCompleted, "lottery is over");
        //payment
        for(uint i = 0;i < _tickets.length; i++) {
            ticketOwner[msg.sender] = _tickets[i];
            _safeMint(msg.sender, _tickets[i]);
            emit newTicketPurchased(msg.sender, _tickets[i]);
        }
       if(!hasPlayed[msg.sender]){
           NumberOfPlayers++;
       }
       
    }


    function setLotteryWinners(address[] memory _winners) public {
        lotterydetails.isActive = false;
        require(msg.sender == oracle, "caller not oracle address");
        address[] memory winners;
        for(uint i = 0; i < NumberOfWinners; i ++) {
            isWinner[_winners[i]] = true;
            winners[i] = _winners[i];
            emit winnerAnnouced (winners[i]);
        }
    }

    function claimLottery() public {
        require(isWinner[msg.sender] == true, "caller not winner");
        //payment to winners with individual price
        //payment to charity if set
    }



    event newTicketPurchased(address _player, uint _ticketID);
    event winnerAnnouced (address _winner);

    constructor() ERC721("Lottery", "LTR") {
        lotterydetails.startTime = 1613110721;
        lotterydetails.endTime = 1739341121;
        lotterydetails.isCompleted = false;
        lotterydetails.isActive = true;
        NumberOfWinners = 5;
        individualPrice = lotterydetails.price / NumberOfWinners;
        oracle = address(0);

    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }
}
