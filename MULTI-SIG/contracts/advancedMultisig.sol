// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Multisignatory {
    // State Variables
    uint8 public quorum;
    uint8 public noOfValidSigners;
    uint256 public txCount;

     // Struct
    struct Transaction {
        uint256 amount;
        address sender;
        address recipient;
        bool isCompleted;
        uint256 timestamp;
        uint256 noOfApproval;
        address tokenAddress;
    }

    mapping(address => bool) public isValidSigner; // True or false
    mapping(uint => Transaction) public transactions; // txId => Transaction
    mapping(uint => mapping(address => bool)) public hasSigned; // txId => (signer => has signed)

    // Custom Errors
    error NotValidSigner();
    error TransactionAlreadyCompleted();
    error QuorumReached();
    error AlreadySigned();
    error InsufficientFunds();
    error AddressZeroNotAllowed();
    error InvalidTransactionId();
    error InvalidQuorum();
    error ZeroSignersRequired();

    // Modifiers
    modifier onlyValidSigner() {
        if(!isValidSigner[msg.sender]) revert NotvalidSigner();
        _;        
    }
    modifier transactionExists(uint256 _txId) {
        if (_txId == 0 || _txId > txCount) revert InvalidTransactionId();
        _;
    }

    modifier notCompleted(uint256 _txId) {
        if (transactions[_txId].isCompleted) revert TransactionAlreadyCompleted();
        _;
    }

    modifier notSigned(uint256 _txId) {
        if (hasSigned[_txId][msg.sender]) revert AlreadySigned();
        _;
    }

    modifier sufficientFunds(uint256 _amount, address _tokenAddress) {
        if (IERC20(_tokenAddress).balanceOf(address(this)) < _amount) revert InsufficientFunds();
        _;
    }

    modifier validAddress(address _address) {
        if (_address == address(0)) revert AddressZeroNotAllowed();
        _;
    }

     // Events
    event TransferRequestCreated(uint256 indexed txId, address sender, address recipient, uint256 amount, address tokenAddress);
    
    event TransferRequestApproved(uint256 indexed txId, address signer, uint256 currentApprovals);

    constructor(uint8 _quorum, address[] memory _validSigners) {
        if (_quorum == 0) revert InvalidQuorum();
        if (_validSigners.length == 0) revert ZeroSignersRequired();

        quorum = _quorum;
        for (uint256 i = 0; i < _validSigners.length; i++) {
            address signer = _validSigners[i];
            if (signer == address(0)) revert AddressZeroNotAllowed();
            isValidSigner[signer] = true;
        }

        if (!isValidSigner[msg.sender]) {
            isValidSigner[msg.sender] = true;
            noOfValidSigners = uint8(_validSigners.length + 1);
        } else {
            noOfValidSigners = uint8(_validSigners.length);
        }
    }

    function createTransferRequest(
        uint256 _amount,
        address _recipient,
        address _tokenAddress
    ) external onlyValidSigner validAddress(msg.sender) validAddress(_tokenAddress) sufficientFunds(_amount, _tokenAddress) {
        if (_amount == 0) revert InsufficientFunds();
        if (_recipient == address(0)) revert AddressZeroNotAllowed();

        uint256 newTxId = ++txCount;
        Transaction storage newTx = transactions[newTxId];

        newTx.amount = _amount;
        newTx.sender = msg.sender;
        newTx.recipient = _recipient;
        newTx.timestamp = block.timestamp;
        newTx.tokenAddress = _tokenAddress;
        newTx.noOfApproval = 1;
        hasSigned[newTxId][msg.sender] = true;

        emit TransferRequestCreated(newTxId, msg.sender, _recipient, _amount, _tokenAddress);
    }

    function approveTransferRequest(uint256 _txId)
        external
        onlyValidSigner
        transactionExists(_txId)
        notCompleted(_txId)
        notSigned(_txId)
    {
        Transaction storage tx = transactions[_txId];

        tx.noOfApproval += 1;
        hasSigned[_txId][msg.sender] = true;

        emit TransferRequestApproved(_txId, msg.sender, tx.noOfApproval);

        if (tx.noOfApproval >= quorum) {
            executeTransaction(_txId);
        }
    }

    function executeTransaction(uint256 _txId) internal notCompleted(_txId) {
        Transaction storage tx = transactions[_txId];
        IERC20 token = IERC20(tx.tokenAddress);
        token.transfer(tx.recipient, tx.amount);
        tx.isCompleted = true;
    }

    function withdraw(uint256 _amount, address _tokenAddress) external {
        // Implement withdraw logic
    }

    function updateQuorum(uint8 _newQuorum) external {
        // Implement quorum update logic
    }   

}