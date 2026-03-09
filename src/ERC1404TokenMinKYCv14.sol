// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "./IERC1404.sol";


contract ERC1404TokenMinKYCv14 is ERC20, Ownable, IERC1404 {

	// Set receive and send restrictions on investors
	// date is Linux Epoch datetime
	// Default values is 0 which means investor is not whitelisted
    mapping (address => uint256) private _receiveRestriction;  
	mapping (address => uint256) private _sendRestriction;

	// These addresses act as whitelist authority and can call modifyKYCData
	// There is possibility that issuer may let third party like Exchange to control 
	// whitelisting addresses 
    mapping (address => bool) private _whitelistControlAuthority;

	event TransferRestrictionDetected( address indexed from, address indexed to, string message, uint8 errorCode );
	event BurnTokens(address indexed account, uint256 amount);
	event MintTokens(address indexed account, uint256 amount);
	event KYCDataForUserSet (address indexed account, uint256 receiveRestriction, uint256 sendRestriction);
	event HoldingPeriodReset(uint64 _tradingHoldingPeriod);
	event WhitelistAuthorityStatusSet(address user);
	event WhitelistAuthorityStatusRemoved(address user);
	event TransferFrom( address indexed spender, address indexed sender, address indexed recipient, uint256 amount );
	event IssuerForceTransfer (address indexed from, address indexed to, uint256 amount);

	string public constant version = "1.4";


	uint8 private immutable _decimals;	
	uint64 public currentTotalInvestors = 0;		

	// Holding period in EpochTime, if set in future then it will stop 
	// all transfers between investors
	uint64 public tradingHoldingPeriod = 1;


	// Transfer Restriction Codes and corresponding error message in _messageForTransferRestriction
	uint8 private constant NO_TRANSFER_RESTRICTION_FOUND = 0;
	uint8 private constant TRANSFERS_DISABLED = 1;
	uint8 private constant TRANSFER_VALUE_CANNOT_ZERO = 2;
	uint8 private constant SENDER_NOT_WHITELISTED_OR_BLOCKED = 3;
	uint8 private constant RECEIVER_NOT_WHITELISTED_OR_BLOCKED = 4;
	uint8 private constant SENDER_UNDER_HOLDING_PERIOD = 5;
	uint8 private constant RECEIVER_UNDER_HOLDING_PERIOD = 6;
	string[] private _messageForTransferRestriction = [
		"No transfer restrictions found", 
		"All transfers are disabled because Holding Period is not yet expired", 
		"Transfer amount must be greater than zero",
		"Sender is not whitelisted or blocked",
		"Receiver is not whitelisted or blocked",
		"Sender is whitelisted but is not eligible to send tokens and under holding period (KYC time restriction)",
		"Receiver is whitelisted but is not yet eligible to receive tokens in his wallet (KYC time restriction)"
	];	



	constructor(
		uint256 _initialSupply, 
		string memory _name,  
		string memory _symbol, 
		// uint64 _allowedInvestors, 
		uint8 _decimalsPlaces, 
		// string memory _ShareCertificate, 
		// string memory _CompanyHomepage, 
		// string memory _CompanyLegalDocs, 
		address _atomicSwapContractAddress,
		uint64  _tradingHoldingPeriod
	) ERC20(_name, _symbol)  {

			address tmpSenderAddress = msg.sender;

			_decimals = _decimalsPlaces;
			tradingHoldingPeriod = _tradingHoldingPeriod;

			// These variables set EPOCH time    1 = 1 January 1970
			_receiveRestriction[tmpSenderAddress] = 1;
			_sendRestriction[tmpSenderAddress] = 1;
			_receiveRestriction[_atomicSwapContractAddress] = 1;
			_sendRestriction[_atomicSwapContractAddress] = 1;

			// add message sender to whitelist authority list
			_whitelistControlAuthority[tmpSenderAddress] = true;


			_mint(tmpSenderAddress , _initialSupply);
			emit MintTokens(tmpSenderAddress, _initialSupply);
	}




	// ------------------------------------------------------------------------
	// Modifiers for this contract 
	// ------------------------------------------------------------------------
    modifier onlyWhitelistControlAuthority () {

	  	require(_whitelistControlAuthority[msg.sender] == true, "Only authorized addresses can control whitelisting of holder addresses");
        _;

    }

    modifier notRestricted (
		address from, 
		address to, 
		uint256 value 
	) {

        uint8 restrictionCode = detectTransferRestriction(from, to, value);
		if( restrictionCode != NO_TRANSFER_RESTRICTION_FOUND ) {

			string memory errorMessage = messageForTransferRestriction(restrictionCode);
			emit TransferRestrictionDetected( from, to, errorMessage, restrictionCode );
        	revert(errorMessage);

		} else 
        	_;

    }




	// ERC20 interface
    function decimals() public view override returns (uint8) {
        return _decimals;
    }
	


    function mint (address account, uint256 amount)		
    external        
	Ownable.onlyOwner
    returns (bool)
    {
		require ( account != address(0), "Minting address cannot be zero");
		require ( _receiveRestriction[account] != 0, "Address is not yet whitelisted by issuer" );
		require ( amount > 0, "Zero amount cannot be minted" );

		ERC20._mint(account, amount);		 

        if( ERC20.balanceOf(account) == amount && account != Ownable.owner() ) {
            currentTotalInvestors = currentTotalInvestors + 1;
        }

		emit MintTokens(account, amount);
		return true;
    }


    function burn (address account, uint256 amount)
	external     
	Ownable.onlyOwner
    returns (bool)
    {
		require( account != address(0), "Burn address cannot be zero");
		require ( amount > 0, "Zero amount cannot be burned" );		

		ERC20._burn(account, amount);

		// burning will decrease currentTotalInvestors if address balance becomes 0		
		if( ERC20.balanceOf(account) == 0 && account != Ownable.owner() && currentTotalInvestors > 0)
		{
			currentTotalInvestors = currentTotalInvestors - 1;
		}


		 emit BurnTokens(account, amount);		 
		 return true;
    }




    function setTradingHoldingPeriod (
		uint64 _tradingHoldingPeriod
	) 
	external 
	Ownable.onlyOwner {

		 tradingHoldingPeriod = _tradingHoldingPeriod;
		 emit HoldingPeriodReset(_tradingHoldingPeriod);

    }




	//-----------------------------------------------------------------------
    // Manage whitelist authority and KYC status
	//-----------------------------------------------------------------------
	
	function setWhitelistAuthorityStatus(
		address user
	) 
	external 
	Ownable.onlyOwner {

		_whitelistControlAuthority[user] = true;
		emit WhitelistAuthorityStatusSet(user);

	}

	function removeWhitelistAuthorityStatus(
		address user
	) 
	external 
	Ownable.onlyOwner {

		delete _whitelistControlAuthority[user];
		emit WhitelistAuthorityStatusRemoved(user);

	}	

	function getWhitelistAuthorityStatus(
		address user
	) 
	external 
	view
	returns (bool) {

		 return _whitelistControlAuthority[user];

	}	
	


  	// Set Receive and Send restrictions on addresses. Both values are EPOCH time
	function modifyKYCData (
		address account, 
		uint256 receiveRestriction, 
		uint256 sendRestriction 
	) 
	external 
	onlyWhitelistControlAuthority { 
		setupKYCDataForUser( account, receiveRestriction, sendRestriction );
	}



	function setupKYCDataForUser (
		address account, 
		uint256 receiveRestriction, 
		uint256 sendRestriction
	) internal {	
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
	//-----------------------------------------------------------------------




	//-----------------------------------------------------------------------
	// These are ERC1404 interface implementations 
	//-----------------------------------------------------------------------

    function detectTransferRestriction (address _from, address _to, uint256 value) 
	override
	public 
	view 
	returns ( uint8 status )  {	

	      	// check if holding period is in effect on overall transfers and sender is not owner. 
			// only owner is allowed to transfer under holding period
		  	if(block.timestamp < tradingHoldingPeriod && _from != Ownable.owner()) {
			 	return TRANSFERS_DISABLED;   
			}

		  	if( value < 1) {
		  	  	return TRANSFER_VALUE_CANNOT_ZERO;   
			}

		  	if( _sendRestriction[_from] == 0 ) {
				return SENDER_NOT_WHITELISTED_OR_BLOCKED;   // Sender is not whitelisted or blocked
			}

		  	if( _receiveRestriction[_to] == 0 ) {
				return RECEIVER_NOT_WHITELISTED_OR_BLOCKED;	// Receiver is not whitelisted or blocked
			}

			if( _sendRestriction[_from] > block.timestamp ) {
				return SENDER_UNDER_HOLDING_PERIOD;	// Receiver is whitelisted but is not eligible to send tokens and still under holding period (KYC time restriction)
			}

			if( _receiveRestriction[_to] > block.timestamp ) {
				return RECEIVER_UNDER_HOLDING_PERIOD;	// Receiver is whitelisted but is not yet eligible to receive tokens in his wallet (KYC time restriction)
			}

            return NO_TRANSFER_RESTRICTION_FOUND;

    }


    function messageForTransferRestriction (uint8 restrictionCode)
	override
    public	
    view 
	returns ( string memory message )
    {

		if(restrictionCode <= (_messageForTransferRestriction.length - 1) ) {
			message = _messageForTransferRestriction[restrictionCode];
		} else {
			message = "Error code is not defined";
		}

    }
	//-----------------------------------------------------------------------





	//-----------------------------------------------------------------------
	// Transfers
	//-----------------------------------------------------------------------

    function transfer(
        address recipient,
        uint256 amount
    ) 	
	override
	public 
	notRestricted (msg.sender, recipient, amount)
	returns (bool) {

		transferSharesBetweenInvestors ( msg.sender, recipient, amount, true );
		return true;

    }



    function transferFrom (
        address sender,
        address recipient,
        uint256 amount
    ) 
	public
	override
	notRestricted (sender, recipient, amount)
	returns (bool)	{	

		transferSharesBetweenInvestors ( sender, recipient, amount, false );
		emit TransferFrom( msg.sender, sender, recipient, amount );
		return true;

    }



	// Force transfer of token back to Issuer account. Issuer account who is also the owner of the token has full authority to take back tokens from any account. This function can be used in case of any emergency or dispute resolution.
    // For example, if any investor is found to be involved in any fraudulent activity or any investor is not following the terms 
    // and conditions of the investment, then issuer can take back tokens from that investor's account by calling this function. 
    // This function can also be used to take back tokens from any account in case of any dispute resolution between issuer and investor.
    // This function will not check any transfer restrictions and will directly transfer tokens from any account to issuer account. 
    // This function can only be called by the owner of the token which is the issuer account. This function will emit an event 
    // IssuerForceTransfer with details of the transfer.
	function forceTransferToken (
        address from,
        uint256 amount
	) 
	Ownable.onlyOwner
	external 
	returns (bool)  {
		
		transferSharesBetweenInvestors ( from, Ownable.owner(), amount, true );
		emit IssuerForceTransfer (from, Ownable.owner(), amount);
		return true;

	}



	// Transfer tokens from one account to other
	// Also manage current number of token holders
	function transferSharesBetweenInvestors (
        address sender,
        address recipient,
        uint256 amount,
		bool simpleTransfer	   // true = transfer,   false = transferFrom
	) 
	internal {

		if( simpleTransfer == true ) {
			ERC20._transfer(sender, recipient, amount);
		} else {
			ERC20._spendAllowance(sender, msg.sender, amount);
			ERC20._transfer(sender, recipient, amount);

			// ERC20.transferFrom() internally calls _spendAllowance() then _transfer().
			// However because your contract overrides transferFrom(), the call will resolve back to 
			// your contract in some contexts depending on inheritance chain.
			// This can cause recursion or unexpected allowance handling.
			// That is why direct call to transferFrom (below) is avoided and instead _spendAllowance and 
			// _transfer are called separately to ensure correct behavior.
			
			// ERC20.transferFrom(sender, recipient, amount);
		}

        if( recipient != Ownable.owner() && ERC20.balanceOf(recipient) == amount ) {
            currentTotalInvestors = currentTotalInvestors + 1;
        }
		if( ERC20.balanceOf(sender) == 0 && sender != Ownable.owner() && currentTotalInvestors > 0)
		{
			currentTotalInvestors = currentTotalInvestors - 1;
		}

	}



}


/*

	Version 1.1

	1. Forceful take over of token   ( forceTransferToken )

	2. Bulk whitelisting  ( bulkWhitelistWallets )


	Version 1.2

	1. Dedicated transfer restriction codes defined in detectTransferRestriction and their descriptions in messageForTransferRestriction

	2. Events for multiple activities being performed  

	3. tradingHoldingPeriod - Holding period has been implemented. Admin can setup a future date and all investor transfers will be disabled 
	till that date. Previous it was a boolean variable with true and false


	Version 1.3

	1. Integration with openzeppelin library
	
	2. detectTransferRestriction  restructure


    version 1.4

    1. Removal of total number of investors allowed in the system.

*/