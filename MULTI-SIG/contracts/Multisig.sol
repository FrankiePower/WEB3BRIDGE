// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Multisig {
    //State Variables
    uint8 public quorum;
    uint8 public noOfValidSigners;
    uint256 public txCount;

    //Struct
    struct Transaction {
        uint256 amount;
        address sender;
        address recipient;
        bool isCompleted;
        uint256 timestamp;
        uint256 noOfApproval;
        address tokenAddress;
        address[] transactionSigners; //as opposed to a mapping?
    }

    mapping(address => bool) isValidSigner; //true or false

    mapping(uint => Transaction) transactions; // txId => each Transaction.

    mapping (address => mapping (uint256 => bool)) hasSigned; // mapping an address to a transaction ID to check if it's true or false. is this even necessary?

    event TransferRequestCreated(uint256 indexed txId, address sender, address recipient, uint256 amount, address tokenAddress);

    event TransferRequestApproved(uint256 indexed txId, address signer, uint256 currentApprovals);

    constructor(uint8 _quorum, address[] memory _validSigners){

        require(_quorum > 0, "Quorum must be greater than zero");

        require(_validSigners.length > 0, "At least one valid signer required");

        quorum = _quorum;

        for(uint256 i = 0; i <  _validSigners.length; i++){

            require(_validSigners[i] != address(0),"Zero Address not Allowed!");

            isValidSigner[_validSigners[i]] = true; //declaring all the addresses to be valid signers.

            if(!isValidSigner[msg.sender]){

            isValidSigner[msg.sender] = true;

            noOfValidSigners = uint8(_validSigners.length);

            noOfValidSigners += 1;
            
            }
        }

    }
    function createTransferRequest(uint256 _amount, address _recipient, address _tokenAddress) external{

        require(msg.sender != address(0), "Address Zero found");

        require(_tokenAddress != address(0), "Address Zero Found");

        require(IERC20(_tokenAddress).balanceOf(address(this)) >= _amount,"insufficient funds");

        require(isValidSigner[msg.sender],"invalid signer");

        require(_amount > 0, "Can't send zero amount");

        require(_recipient != address(0), "Address Zero Found");

        uint256 _newTxId = txCount + 1; // initializing a state variable and assigning an increment of transaction count.
        Transaction storage newTx = transactions[_newTxId];

        newTx.amount = _amount;
        newTx.sender = msg.sender;
        newTx.recipient = _recipient;
        newTx.timestamp = block.timestamp;
        newTx.noOfApproval += 1;
        newTx.tokenAddress = _tokenAddress;
        newTx.transactionSigners.push(msg.sender);

        hasSigned[msg.sender][_newTxId] = true;

        txCount = _newTxId;

        emit TransferRequestCreated(_newTxId, msg.sender, _recipient, _amount, _tokenAddress);
    

    }

    function approveTransferRequest(uint8 _txId) external{

        require(_txId > 0 && _txId <= txCount, "Invalid transaction ID");

        Transaction storage newTx = transactions[_txId];



    hasSigned[msg.sender][_txId] = true;

        require(IERC20(newTx.tokenAddress).balanceOf(address(this)) >= newTx.amount,"Insufficient Funds");

        require(!newTx.isCompleted,"Transaction already completed");

        require(newTx.noOfApproval < quorum,"approvals already reached");

        require(isValidSigner[msg.sender],"invalid signer");

        require(msg.sender != address(0), "Address Zero found");

        require(!hasSigned[msg.sender][_txId],"can't sign twice");

        hasSigned[msg.sender][_txId] = true;

        newTx.noOfApproval += 1;

        newTx.transactionSigners.push(msg.sender);  

        emit TransferRequestApproved(_txId, msg.sender, newTx.noOfApproval);         
    
}
 function withdraw(uint256 _amount, address _tokenAddress) external {

    }

    function updateQuorum(uint8 _newQuorum) external {

    }
}
    
}
