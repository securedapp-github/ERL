// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

// Importing OpenZeppelin contracts for ERC20 token functionality and extensions
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

// Define the ERiyal contract, inheriting from OpenZeppelin's ERC20, ERC20Burnable, ERC20Pausable, AccessControl, and ERC20Permit
contract ERiyal is ERC20, ERC20Burnable, ERC20Pausable, AccessControl, ERC20Permit {
    // Define roles for pausing and minting
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // State variables for token transfer fee
    bool public feeActive;           // Indicates if the transfer fee is active
    uint256 public feePercent;       // The percentage of the transfer fee
    address public feeWallet;        // Address that receives the transfer fee

    // Constructor initializes the contract with roles and token details
    constructor()
        ERC20("E Riyal", "ERL")
        ERC20Permit("E Riyal")
    {
        // Grant the default admin, pauser, and minter roles
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        feeActive = false; // Initialize fee status as inactive
    }

    // Function to pause token transfers
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    // Function to unpause token transfers
    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    // Function to mint new tokens, restricted to minters
    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    // Function to change the fee status, percentage, and wallet address
    function changeFeeStatus(bool status, uint256 _feePercent, address _feeWallet)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        feeActive = status;          // Update the fee activation status
        feePercent = _feePercent;    // Update the fee percentage
        if(_feeWallet != address(0)) feeWallet = _feeWallet; // Update the fee wallet address if valid
    }

    // Override transfer function to include fee logic
    function transfer(address to, uint256 value) public override returns (bool) {
        address owner = _msgSender();
        if (feeActive) {
            uint256 fee;
            fee = (value * feePercent) / 10000; // Calculate fee based on percentage
            _transfer(owner, feeWallet, fee);  // Transfer fee to feeWallet
            value = value - fee;                // Adjust the value to transfer after fee deduction
        }
        _transfer(owner, to, value); // Transfer the remaining value to the recipient
        return true;
    }

    // Override transferFrom function to include fee logic
    function transferFrom(address from, address to, uint256 value) public override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value); // Spend allowance for the transfer
        if (feeActive) {
            uint256 fee;
            fee = (value * feePercent) / 10000; // Calculate fee based on percentage
            _transfer(from, feeWallet, fee);   // Transfer fee to feeWallet
            value = value - fee;               // Adjust the value to transfer after fee deduction
        }
        _transfer(from, to, value); // Transfer the remaining value to the recipient
        return true;
    }

    // The following function is an override required by Solidity to manage paused state
    function _update(address from, address to, uint256 value)
        internal
        override(ERC20, ERC20Pausable)
    {
        super._update(from, to, value); // Call the parent contract's update function
    }
}
