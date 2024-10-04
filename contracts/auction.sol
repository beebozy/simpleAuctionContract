// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleAuction {
    // Parameters of the auction
    address payable public owner;       // Address of the auction owner
    uint256 public auctionEndTime;      // Timestamp for when the auction ends
    address public highestBidder;       // Address of the highest bidder
    uint256 public highestBid;          // Current highest bid

    // Mapping to store pending returns for outbid bidders
    mapping(address => uint256) public pendingReturns;

    // State to indicate if the auction has ended
    bool public ended;

    // Events that will be emitted on changes
    event HighestBidIncreased(address bidder, uint256 amount);
    event AuctionEnded(address winner, uint256 amount);

    // Modifier to restrict access to the owner only
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    // Constructor to initialize the contract with auction details
    constructor(uint256 _biddingTime) {
        owner = payable(msg.sender);            // Set the auction owner
        auctionEndTime = block.timestamp + _biddingTime; // Set the auction end time
    }

    // Function to place a bid
    function bid() external payable {
        // Revert if auction has ended
        require(block.timestamp < auctionEndTime, "Auction already ended");

        // Revert if the bid is not higher than the current highest bid
        require(msg.value > highestBid, "There already is a higher bid");

        // If there was a previous highest bid, add it to the pending returns
        if (highestBid != 0) {
            pendingReturns[highestBidder] += highestBid;
        }

        // Update the highest bid and bidder
        highestBidder = msg.sender;
        highestBid = msg.value;
        emit HighestBidIncreased(msg.sender, msg.value);
    }

    // Function to withdraw the bids that were overbid
    function withdraw() external returns (bool) {
        uint256 amount = pendingReturns[msg.sender];
        require(amount > 0, "No pending returns");

        // Set pending returns to zero before transfer to prevent reentrancy attack
        pendingReturns[msg.sender] = 0;

        // Transfer the funds back to the bidder
        if (!payable(msg.sender).send(amount)) {
            // If the send fails, restore the pending returns
            pendingReturns[msg.sender] = amount;
            return false;
        }
        return true;
    }

    // Function to end the auction and send funds to the owner
    function endAuction() external onlyOwner {
        // Revert if the auction has already been ended
        require(!ended, "Auction has already ended");

        // Revert if the auction has not yet ended
        require(block.timestamp >= auctionEndTime, "Auction not yet ended");

        // Mark the auction as ended
        ended = true;

        // Emit the auction ended event
        emit AuctionEnded(highestBidder, highestBid);

        // Transfer the highest bid to the auction owner
        owner.transfer(highestBid);
    }
}
