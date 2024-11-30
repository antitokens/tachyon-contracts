// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Migrations {
    address public owner;
    uint public last_completed_migration;

    // Modifier to restrict access to the owner
    modifier restricted() {
        require(msg.sender == owner, "NOT_OWNER");
        _;
    }

    // Constructor to set the initial owner
    constructor() {
        owner = msg.sender;
    }

    // Set the last completed migration step
    function setCompleted(uint completed) public restricted {
        last_completed_migration = completed;
    }

    // Upgrade the contract to a new address
    function upgrade(address new_address) public restricted {
        Migrations upgraded = Migrations(new_address);
        upgraded.setCompleted(last_completed_migration);
    }
}
