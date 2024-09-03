// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Airdrop is Ownable {
    IERC20 public token;
    bytes32 public merkleRoot;
    mapping(address => bool) public claimed;

    event Claimed(address indexed user, uint256 amount);

    constructor(IERC20 _token, bytes32 _merkleRoot) Ownable(msg.sender) {
        token = _token;
        merkleRoot = _merkleRoot;
    }

    function claim(uint256 amount, bytes32[] calldata proof) external {
        
        require(!claimed[msg.sender], "Already claimed");

        bytes32 leaf =keccak256(abi.encodePacked(msg.sender, amount));

        require(MerkleProof.verify(proof, merkleRoot, leaf), "Invalid proof");
        
        claimed[msg.sender] = true;

        require(token.transfer(msg.sender, amount), "Transfer failed");

        emit Claimed(msg.sender, amount);
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function withdrawRemainingTokens() external onlyOwner {
        
        require(balance > 0, "No tokens to withdraw");
        
        require(token.transfer(owner(), balance), "Transfer failed");

        uint256 balance = token.balanceOf(address(this));

    }
}