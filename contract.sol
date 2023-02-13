// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts@4.8.1/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts@4.8.1/security/Pausable.sol";
import "@openzeppelin/contracts@4.8.1/access/Ownable.sol";


interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function stakes(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function decimals() external view returns(uint8);
}

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
    address public usdt;
    uint public NumberOfWinners;
    uint public pricePool;
    uint public charity;
    
    address public charityAddress;

    lotteryStruct public lotterydetails;


     mapping(uint => address) public ticketOwner;
     mapping(address => bool) public hasPlayed;
     mapping(address => bool) public hasClaimed;
     mapping(address => bool) public isWinner;
     mapping(address => uint) public totalWins;




    function purchaseTicket (uint[] memory _tickets) public{
        require(block.timestamp > lotterydetails.startTime, "lottery not started!");
        require(block.timestamp < lotterydetails.endTime, "lottery is ended");
        require(lotterydetails.isActive == true, "lottery not active");
        require (!lotterydetails.isCompleted, "lottery is over");
        IERC20(usdt).transferFrom(msg.sender, address(this), (ticketPrice*_tickets.length));
        for(uint i = 0;i < _tickets.length; i++) {
            ticketOwner[_tickets[i]] = msg.sender;
            _safeMint(msg.sender, _tickets[i]);
            emit newTicketPurchased(msg.sender, _tickets[i]);
        }
       if(!hasPlayed[msg.sender]){
           NumberOfPlayers++;
       }
       hasPlayed[msg.sender] = true;
    }


    function setLotteryWinners(uint[] memory _winners) public {
        lotterydetails.isActive = false;
        //called by backend
        require(msg.sender == oracle, "caller not oracle address");
        for(uint i = 0; i < NumberOfWinners; i ++) {
            address winner = ticketOwner[_winners[i]];
            isWinner[winner] = true;
            totalWins[winner] += getRewards();
            emit winnerAnnounced (winner, getRewards());
        }
    }

    function claimLottery() public {
        require(isWinner[msg.sender] == true, "caller not winner");
        require(!hasClaimed[msg.sender], "caller has claimed");
        uint wins = totalWins[msg.sender];
        IERC20(usdt).transfer(msg.sender, wins);
        hasClaimed[msg.sender] = true;
        emit priceWithdrawn(msg.sender, wins);
    }


    function getRewards() public view returns (uint){
        return pricePool / NumberOfWinners;
    }

    function emitToCharity() public {
        require(!lotterydetails.isActive , "lottery not completed");
        IERC20(usdt).transfer(charityAddress, charity);
        charity = 0;
    }



    event newTicketPurchased(address _player, uint _ticketID);
    event winnerAnnounced (address _winner, uint totalWins);
    event priceWithdrawn (address _winner, uint price);

    constructor(uint _charity, uint _pricePool) ERC721("Lottery", "LTR") {
        lotterydetails.startTime = 1613110721;
        lotterydetails.endTime = 1739341121;
        lotterydetails.isCompleted = false;
        lotterydetails.isActive = true;
        charity = ((_pricePool * _charity)/100);
        uint fee = ((_pricePool * 5)/100);
        pricePool = _pricePool - (charity + fee);
        NumberOfWinners = 5;
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
