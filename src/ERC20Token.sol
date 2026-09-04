// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";


contract ERC20Token is ERC20Pausable, Ownable {


	event IssuerForceTransfer (address indexed from, address indexed to, uint256 amount);

	constructor(uint256 _initialSupply, string memory _name ) ERC20(_name, _name) {
		_mint(msg.sender , _initialSupply);
	}

    function pause() 
	external 
	onlyOwner {
        _pause();
    }

    function unpause() 
	external 
	onlyOwner {
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
