// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

/// @title ERC20 Token for Staking App
/// @author 
/// @notice 
/// @dev 

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {
    constructor()ERC20("Token","TOK"){
    }
    function mint( )public payable{
        uint256 amount=msg.value*100;
        _mint(msg.sender,amount);
    }
    
}