// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/ERC1404TokenMinKYCv13.sol";
import "./helpers/ERC1404_Base_Setup.sol";

// --------------------------------------------------------------------------------
// --------------------------------------------------------------------------------
// Test Suite 1   -  Test Default Values set while setting up security token
// --------------------------------------------------------------------------------
// --------------------------------------------------------------------------------

contract ERC1404_Default_Values is ERC1404_Base_Setup {
    function setUp() public override {
        ERC1404_Base_Setup.setUp();
    }

    // Check default decimal places which must be 18
    function testCheckDecimals() public {
        assertEq(token.decimals(), decimalsPlaces);
    }

    // Check default total supply of tokens
    function testCheckTotalSupply() public {
        assertEq(token.totalSupply(), initialSupply);
    }

    // Check owner contains the total balance minted
    function testCheckBalanceOfIssuer() public {
        assertEq(token.balanceOf(token.owner()), initialSupply);
    }

    // Check any other address that must not contain any tokens
    function testCheckDefaultBalanceOfAccount(
        address randomAddress
    ) public {
        vm.assume(randomAddress != address(this) && randomAddress != token.owner());
        assertEq(token.balanceOf(randomAddress), 0);
    }

    // Check swap contract address is whitelisted
    function testCheckAccountIsWhitelisted() public {
        (uint receiveRestriction, uint sendRestriction) = token.getKYCData(atomicSwapContractAddress);
        assertEq(receiveRestriction, 1);
        assertEq(sendRestriction, 1);
    }

    // Check any random address is not whitelisted
    function testCheckAccountIsNotWhitelisted(
        address randomAddress
    ) public {
        vm.assume(randomAddress != address(this) && randomAddress != token.owner());
        (uint receiveRestriction, uint sendRestriction) = token.getKYCData(randomAddress);
        assertEq(receiveRestriction, 0);
        assertEq(sendRestriction, 0);
    }

    // Test tradingHoldingPeriod is set to it's default value 1
    function testTradingHoldingPeriodHasDefaultValue() public {
        assertEq(token.tradingHoldingPeriod(), tradingHoldingPeriod);
    }

    // Test allowedInvestors is set to it's default value 0
    function testAllowedInvestorsSetToDefaultValue() public {
        assertEq(token.allowedInvestors(), allowedInvestors);
    }

    function testCheckDefaultNameAndSymbolValues() public {
        assertEq(token.name(), name);
        assertEq(token.symbol(), symbol);
        assertEq(token.IssuancePlatform(), "DigiShares");
        assertEq(token.issuanceProtocol(), "ERC-1404");
        assertEq(token.allowedInvestors(), allowedInvestors);
        assertEq(token.currentTotalInvestors(), 0);
    }
}
