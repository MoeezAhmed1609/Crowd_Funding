// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Crowd_Funding{

    mapping (address => uint) Contributors;

    address public manager;
    uint public minimum_contribution;
    uint public target;
    uint public deadline;
    uint public raised_amount;
    uint public total_contributors;

    constructor(uint _target , uint _deadline) {
        manager = msg.sender;
        target = _target;
        deadline = block.timestamp + _deadline;
        minimum_contribution = 100 wei;
    }

    modifier onlyOwner {
        require(msg.sender == manager , "You are not manager, aborting!");
        _;
    }

    struct Request {
        string description;
        address payable recipient;
        uint amount;
        bool success;
        uint total_voters;
        mapping (address => bool) voters;
    }

    uint public total_request;

    mapping (uint => Request) public Request_Map;

    event Contribution (address _manager ,address _sender , uint _value , address _contract);
    event Contributor_Refund (address manager , address _contributor ,uint _amount , address _contract_address);
    event Request_Created (address _manager , address _recipient , string _description , uint _amount , address _contract);
    event New_Voter (uint _request ,address _voter , address _manager);

    function Contribute () public payable {
        require(block.timestamp < deadline , "Fund raising has reached deadline,");
        require(msg.value >= minimum_contribution , "Not enough Ethers provided, aborting!");

        if (Contributors[msg.sender] == 0){
            total_contributors++;
        }

        Contributors[msg.sender] += msg.value;
        raised_amount += msg.value;

        emit Contribution (manager , msg.sender , msg.value , address(this));
    }

    function Balance () public view returns (uint) {
        return address(this).balance;
    }

    function Refund (address payable _contributor) public payable {

        require(Contributors[_contributor] > 0 , "You don't have any balance!");
        require(block.timestamp > deadline && raised_amount < target , "You cannot refund.");

        _contributor.transfer(Contributors[_contributor]);
        Contributors[_contributor] = 0;

        emit Contributor_Refund (manager , _contributor , Contributors[_contributor] , address(this));

    }

    // Manager POV
    // Create Request
    // Vote request
    // transfer to recipient


    function create_request (
        string memory _description,
        address payable _recipient,
        uint _amount
    ) public onlyOwner {

        Request storage new_request = Request_Map [total_request];
        total_request++;

        new_request.description = _description;
        new_request.recipient = _recipient;
        new_request.amount = _amount;
        new_request.success = false;
        new_request.total_voters = 0;

        emit Request_Created (manager , _recipient , _description , _amount , address(this));
    }

    function Vote_Request (uint _request) public {
        require(Contributors[msg.sender] > 0 , "You cannot vote!");

        Request storage vote_request = Request_Map[_request];

        require(vote_request.success = false , "You have already voted!");

        vote_request.success = true;
        vote_request.total_voters++;

        emit New_Voter (_request , msg.sender , manager);
    }

    function transfer_recipient (uint _request) public onlyOwner returns (bool) {

        require(raised_amount >= target , "Target not reached yet!");

        Request storage request_transfer = Request_Map[_request];

        require(request_transfer.success == false , "This request is fulfilled!");
        require(request_transfer.total_voters > total_contributors / 2 , "Majority didn't agreed yet!");

        request_transfer.recipient.transfer(request_transfer.amount);
        request_transfer.success = true;

        return true;
    }

}