// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./TenderCreation.sol";

contract Bidding {
    struct Bid {
        uint256 bidId;
        uint256 tenderId;
        string contractorMongoId; // Use MongoDBId instead of address
        uint256 bidAmount;
        string proposalDocument;
        uint256 experienceYears;
        uint256 contractorRating;
        bool isApproved;
    }

    struct Milestone {
        uint256 milestoneId;
        string description;
        uint256 deadline;
        uint256 amount;
        bool isApproved;
        bool isRejected;
        bool isPaid;
    }

    struct Contract {
        uint256 contractId;
        uint256 tenderId;
        uint256 winningBidId;
        string contractorMongoId;
        uint256 contractAmount;
        uint256 paidAmount;
        bool isCompleted;
        Milestone[] milestones;
    }

    struct Vote {
        string voterMongoId; // Using MongoDBId instead of blockchain address
        bool vote;
    }

    uint256 private bidCounter;
    uint256 private contractCounter;
    mapping(uint256 => Bid[]) public tenderBids;
    mapping(uint256 => Contract) public contracts;
    mapping(uint256 => mapping(uint256 => Vote[])) public milestoneVotes;
    mapping(string => bool) public governmentOfficials; // Track government officials by MongoDBId
    uint256 public publicVoteWeight = 1;
    uint256 public governmentVoteWeight = 3;

    event BidPlaced(uint256 bidId, uint256 tenderId, string contractorMongoId);
    event ContractCreated(uint256 contractId, uint256 tenderId, string contractorMongoId);
    event MilestoneCreated(uint256 contractId, uint256 milestoneId, string description, uint256 amount, uint256 deadline);
    event VoteCast(uint256 contractId, uint256 milestoneId, string voterMongoId, bool vote);
    event FundsReleased(uint256 contractId, uint256 milestoneId, uint256 amount);
    event MilestoneRejected(uint256 contractId, uint256 milestoneId);

    function placeBid(
        uint256 _tenderId,
        string memory _contractorMongoId,
        uint256 _bidAmount,
        string memory _proposalDocument,
        uint256 _experienceYears,
        uint256 _contractorRating
    ) public {
        bidCounter++;
        tenderBids[_tenderId].push(Bid({
            bidId: bidCounter,
            tenderId: _tenderId,
            contractorMongoId: _contractorMongoId,
            bidAmount: _bidAmount,
            proposalDocument: _proposalDocument,
            experienceYears: _experienceYears,
            contractorRating: _contractorRating,
            isApproved: false
        }));
        emit BidPlaced(bidCounter, _tenderId, _contractorMongoId);
    }

    function approveBid(uint256 _tenderId, uint256 _bidId, Milestone[] memory _milestones) public {
        Bid[] storage bids = tenderBids[_tenderId];
        string memory winningMongoId;
        uint256 winningAmount;
        bool bidFound = false;

        for (uint256 i = 0; i < bids.length; i++) {
            if (bids[i].bidId == _bidId) {
                bids[i].isApproved = true;
                winningMongoId = bids[i].contractorMongoId;
                winningAmount = bids[i].bidAmount;
                bidFound = true;
                break;
            }
        }
        require(bidFound, "Bid not found");

        contractCounter++;
        Contract storage newContract = contracts[contractCounter];
        newContract.contractId = contractCounter;
        newContract.tenderId = _tenderId;
        newContract.winningBidId = _bidId;
        newContract.contractorMongoId = winningMongoId;
        newContract.contractAmount = winningAmount;
        newContract.paidAmount = 0;
        newContract.isCompleted = false;

        for (uint256 i = 0; i < _milestones.length; i++) {
            newContract.milestones.push(_milestones[i]);
            emit MilestoneCreated(contractCounter, _milestones[i].milestoneId, _milestones[i].description, _milestones[i].amount, _milestones[i].deadline);
        }

        emit ContractCreated(contractCounter, _tenderId, winningMongoId);
    }

    function castVote(uint256 _contractId, uint256 _milestoneId, string memory _voterMongoId, bool _vote) public {
        require(contracts[_contractId].contractId != 0, "Contract does not exist");
        require(block.timestamp >= contracts[_contractId].milestones[_milestoneId].deadline, "Voting not started");

        uint256 voteWeight = governmentOfficials[_voterMongoId] ? governmentVoteWeight : publicVoteWeight;
        milestoneVotes[_contractId][_milestoneId].push(Vote(_voterMongoId, _vote));

        emit VoteCast(_contractId, _milestoneId, _voterMongoId, _vote);
    }

    function releaseFunds(uint256 _contractId, uint256 _milestoneId) public {
        require(contracts[_contractId].contractId != 0, "Contract does not exist");
        require(block.timestamp >= contracts[_contractId].milestones[_milestoneId].deadline, "Voting not started");

        uint256 approveVotes = 0;
        uint256 rejectVotes = 0;

        for (uint256 i = 0; i < milestoneVotes[_contractId][_milestoneId].length; i++) {
            if (milestoneVotes[_contractId][_milestoneId][i].vote) {
                approveVotes++;
            } else {
                rejectVotes++;
            }
        }

        if (approveVotes > rejectVotes) {
            contracts[_contractId].milestones[_milestoneId].isApproved = true;
            contracts[_contractId].paidAmount += contracts[_contractId].milestones[_milestoneId].amount;
            emit FundsReleased(_contractId, _milestoneId, contracts[_contractId].milestones[_milestoneId].amount);
        } else {
            contracts[_contractId].milestones[_milestoneId].isRejected = true;
            emit MilestoneRejected(_contractId, _milestoneId);
        }
    }
}
