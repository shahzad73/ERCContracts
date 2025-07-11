// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";


contract ERC20Token is ERC20, Ownable {

	constructor(uint256 _initialSupply, string memory _name ) ERC20(_name, _name) {

			_mint(msg.sender , _initialSupply);

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


}
