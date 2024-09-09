// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

contract Multisig {
    uint8 public quorum;
    mapping (address => bool) ValidSigners; // not using an array, because we would have to loop through it.
                                            // We will go with a mapping of (address to bool) instead.
    constructor() {
        
    }
}