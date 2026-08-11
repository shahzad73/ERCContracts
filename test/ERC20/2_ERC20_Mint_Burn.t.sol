// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "./helpers/ERC20_Base_Setup.sol";
import "forge-std/Test.sol";

contract ERC20_Mint_Burn_Test is ERC20_Base_Setup {
    // Test mint() function
    function test_Mint() public {
        uint256 mintAmount = 1000;
        uint256 totalSupplyBefore = token.totalSupply();
        uint256 recipientBalanceBefore = token.balanceOf(addr1);
        
        // Only owner can mint
        vm.prank(address(this));
        bool success = token.mint(addr1, mintAmount);
        assertTrue(success, "Mint should succeed");
        
        assertEq(token.totalSupply(), totalSupplyBefore + mintAmount, "Total supply should increase");
        assertEq(token.balanceOf(addr1), recipientBalanceBefore + mintAmount, "Recipient balance should increase");
    }

    // Test mint() to zero address should fail
    function test_Mint_ToZeroAddress_Fails() public {
        vm.prank(address(this));
        vm.expectRevert();
        token.mint(address(0), 1000);
    }

    // Test mint() by non-owner should fail
    function test_Mint_ByNonOwner_Fails() public {
        vm.prank(addr1);
        vm.expectRevert();
        token.mint(addr2, 1000);
    }

    // Test burn() function
    function test_Burn() public {
        uint256 burnAmount = 500;
        uint256 totalSupplyBefore = token.totalSupply();
        
        // First transfer some tokens to addr1
        vm.prank(address(this));
        token.transfer(addr1, 1000);
        
        uint256 addr1BalanceBefore = token.balanceOf(addr1);
        
        // Burn from addr1 (only owner can burn)
        vm.prank(address(this));
        bool success = token.burn(addr1, burnAmount);
        assertTrue(success, "Burn should succeed");
        
        assertEq(token.totalSupply(), totalSupplyBefore - burnAmount, "Total supply should decrease");
        assertEq(token.balanceOf(addr1), addr1BalanceBefore - burnAmount, "Address balance should decrease");
    }

    // Test burn() from zero address should fail
    function test_Burn_FromZeroAddress_Fails() public {
        vm.prank(address(this));
        vm.expectRevert();
        token.burn(address(0), 1000);
    }

    // Test burn() by non-owner should fail
    function test_Burn_ByNonOwner_Fails() public {
        vm.prank(addr1);
        vm.expectRevert();
        token.burn(addr2, 500);
    }

    // Test burn() with amount greater than balance should fail
    function test_Burn_InsufficientBalance_Fails() public {
        vm.prank(address(this));
        vm.expectRevert();
        token.burn(addr1, 1000); // addr1 has 0 balance
    }

    // Test totalSupply after multiple mints and burns
    function test_TotalSupply_AfterMintAndBurn() public {
        uint256 initialTotalSupply = token.totalSupply();
        
        // Mint 1000 tokens
        vm.prank(address(this));
        token.mint(addr1, 1000);
        assertEq(token.totalSupply(), initialTotalSupply + 1000, "Total supply should increase after mint");
        
        // Burn 500 tokens
        vm.prank(address(this));
        token.burn(addr1, 500);
        assertEq(token.totalSupply(), initialTotalSupply + 500, "Total supply should decrease after burn");
        
        // Mint another 2000 tokens
        vm.prank(address(this));
        token.mint(addr2, 2000);
        assertEq(token.totalSupply(), initialTotalSupply + 2500, "Total supply should increase after second mint");
        
        // Burn 1000 tokens
        vm.prank(address(this));
        token.burn(addr2, 1000);
        assertEq(token.totalSupply(), initialTotalSupply + 1500, "Total supply should decrease after second burn");
    }

    // Test mint and then transfer
    function test_Mint_ThenTransfer() public {
        uint256 mintAmount = 1000;
        uint256 transferAmount = 300;
        
        // Mint tokens to addr1
        vm.prank(address(this));
        token.mint(addr1, mintAmount);
        
        assertEq(token.balanceOf(addr1), mintAmount, "addr1 should have minted tokens");
        assertEq(token.totalSupply(), 11000, "total supply of token should increase 1000");

        // Transfer from addr1 to addr2
        vm.prank(addr1);
        bool success = token.transfer(addr2, transferAmount);
        assertTrue(success, "Transfer should succeed");
        
        assertEq(token.balanceOf(addr1), mintAmount - transferAmount, "addr1 balance should decrease");
        assertEq(token.balanceOf(addr2), transferAmount, "addr2 should receive tokens");

        assertEq(token.totalSupply(), 11000, "total supply of token is still 11000");
    }
}