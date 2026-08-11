// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";


contract ERC20Token is ERC20Pausable, Ownable {

	// Set receive and send restrictions on investors
	// date is Linux Epoch datetime
	// Default values is 0 means there is no restrictions
    mapping (address => uint256) private _receiveRestriction;  
	mapping (address => uint256) private _sendRestriction;

	event KYCDataForUserSet (address indexed account, uint256 receiveRestriction, uint256 sendRestriction);
	event IssuerForceTransfer (address indexed from, address indexed to, uint256 amount);

	constructor(uint256 _initialSupply, string memory _name ) ERC20(_name, _name) {
		_mint(msg.sender , _initialSupply);
	}

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function mint (address to, uint256 amount)		
        external        
		onlyOwner
        returns (bool)
    {
		 super._mint(to, amount);
		 return true;
    }


    function burn (address to, uint256 amount)
		external     
		onlyOwner   
        returns (bool)
    {
		 super._burn(to, amount);
		 return true;
    }




  	// Set Receive and Send restrictions on addresses. Both values are EPOCH time
	function modifyKYCData (
		address account, 
		uint256 receiveRestriction, 
		uint256 sendRestriction 
	) 
	external 
	onlyOwner { 
        require(account != address(0));

		_receiveRestriction[account] = receiveRestriction;
		_sendRestriction[account] = sendRestriction;		
		emit KYCDataForUserSet (account, receiveRestriction, sendRestriction);
	}


	function getKYCData ( 
		address user 
	) 
	external 
	view
	returns ( uint256, uint256 ) {

		return (_receiveRestriction[user] , _sendRestriction[user] );

	}


    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        virtual
        override
    {
        super._beforeTokenTransfer(from, to, amount);

        // Add custom transfer restrictions here
        require( _sendRestriction[from] == 0  ||  _sendRestriction[from] < block.timestamp, "Sender is under send restrictions"); 
        require( _receiveRestriction[to] == 0  ||   _receiveRestriction[to] < block.timestamp, "Receiver is under receive restriction" ); 

    }



	function forceTransferToken (
        address from,
        uint256 amount
	) 
	onlyOwner
	external 
	returns (bool) {
		
		super._transfer(from, owner(), amount);

		emit IssuerForceTransfer (from, Ownable.owner(), amount);
		return true;

	}



}
