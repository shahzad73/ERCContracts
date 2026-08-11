// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "./helpers/ERC20_Base_Setup.sol";
import "forge-std/Test.sol";

contract ERC20_Pause_Unpause_Test is ERC20_Base_Setup {
    // Test pause() function
    function test_Pause() public {
        // Only owner can pause
        vm.prank(address(this));
        token.pause();
        
        assertTrue(token.paused(), "Contract should be paused");
    }

    // Test pause() by non-owner should fail
    function test_Pause_ByNonOwner_Fails() public {
        vm.prank(addr1);
        vm.expectRevert();
        token.pause();
    }

    // Test unpause() function
    function test_Unpause() public {
        // First pause
        vm.prank(address(this));
        token.pause();
        assertTrue(token.paused(), "Contract should be paused");
        
        // Then unpause
        vm.prank(address(this));
        token.unpause();
        assertFalse(token.paused(), "Contract should be unpaused");
    }

    // Test unpause() by non-owner should fail
    function test_Unpause_ByNonOwner_Fails() public {
        // First pause by owner
        vm.prank(address(this));
        token.pause();
        
        // Try to unpause by non-owner
        vm.prank(addr1);
        vm.expectRevert();
        token.unpause();
    }

    // Test transfer() when paused should fail
    function test_Transfer_WhenPaused_Fails() public {
        // Pause the contract
        vm.prank(address(this));
        token.pause();
        
        // Try to transfer
        vm.prank(address(this));
        vm.expectRevert();
        token.transfer(addr1, 100);
    }

    // Test transferFrom() when paused should fail
    function test_TransferFrom_WhenPaused_Fails() public {
        // Pause the contract
        vm.prank(address(this));
        token.pause();
        
        // Approve first
        vm.prank(address(this));
        token.approve(addr1, 100);
        
        // Try to transferFrom
        vm.prank(addr1);
        vm.expectRevert();
        token.transferFrom(address(this), addr2, 100);
    }

    // Test that all users cannot transfer when paused
    function test_AllUsersCannotTransfer_WhenPaused() public {
        // Transfer some tokens to addr1 first (before pausing)
        vm.prank(address(this));
        token.transfer(addr1, 1000);
        
        // Pause the contract
        vm.prank(address(this));
        token.pause();
        
        // Try to transfer from addr1
        vm.prank(addr1);
        vm.expectRevert("ERC20Pausable: token transfer while paused");
        token.transfer(addr2, 100);
        
        // Try to transfer from owner
        vm.prank(address(this));
        vm.expectRevert("ERC20Pausable: token transfer while paused");
        token.transfer(addr3, 100);
    }

    // Test that transfers work normally after unpause
    function test_TransfersWork_AfterUnpause() public {
        // Pause the contract
        vm.prank(address(this));
        token.pause();
        
        // Try to transfer (should fail)
        vm.prank(address(this));
        vm.expectRevert();
        token.transfer(addr1, 100);
        
        // Unpause
        vm.prank(address(this));
        token.unpause();
        
        // Now transfer should work
        vm.prank(address(this));
        bool success = token.transfer(addr1, 100);
        assertTrue(success, "Transfer should succeed after unpause");
        
        assertEq(token.balanceOf(addr1), 100, "addr1 should receive tokens");
    }

    // Test mint() when paused should fail
    function test_Mint_WhenPaused_Fails() public {
        // Pause the contract
        vm.prank(address(this));
        token.pause();
        
        // Try to mint
        vm.prank(address(this));
        vm.expectRevert();
        token.mint(addr1, 1000);
    }

    // Test burn() when paused should fail
    function test_Burn_WhenPaused_Fails() public {
        // Pause the contract
        vm.prank(address(this));
        token.pause();
        
        // Try to burn
        vm.prank(address(this));
        vm.expectRevert();
        token.burn(addr1, 100);
    }

    // Test approve() when paused (approve is not blocked by pause in ERC20Pausable)
    function test_Approve_WhenPaused() public {
        // Pause the contract
        vm.prank(address(this));
        token.pause();
        
        // Approve should still work even when paused (ERC20Pausable only blocks transfers)
        vm.prank(address(this));
        bool success = token.approve(addr1, 100);
        assertTrue(success, "Approve should work even when paused");
        
        assertEq(token.allowance(address(this), addr1), 100, "Allowance should be set");
    }

    // Test pause and unpause multiple times
    function test_MultiplePauseUnpause() public {
        // Pause
        vm.prank(address(this));
        token.pause();
        assertTrue(token.paused(), "Contract should be paused");
        
        // Unpause
        vm.prank(address(this));
        token.unpause();
        assertFalse(token.paused(), "Contract should be unpaused");
        
        // Pause again
        vm.prank(address(this));
        token.pause();
        assertTrue(token.paused(), "Contract should be paused again");
        
        // Unpause again
        vm.prank(address(this));
        token.unpause();
        assertFalse(token.paused(), "Contract should be unpaused again");
        
        // Transfer should work
        vm.prank(address(this));
        bool success = token.transfer(addr1, 100);
        assertTrue(success, "Transfer should work after multiple pause/unpause cycles");
    }
}