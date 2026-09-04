// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "./helpers/ERC20_Base_Setup.sol";
import "forge-std/Test.sol";

contract ERC20_ForceTransfer_Test is ERC20_Base_Setup {
    // Test: Owner can force transfer tokens from another wallet to owner
    function test_OwnerCanForceTransfer() public {
        // Transfer tokens to addr1 first
        vm.prank(address(this));
        token.transfer(addr1, 1000);
        
        uint256 addr1BalanceBefore = token.balanceOf(addr1);
        uint256 ownerBalanceBefore = token.balanceOf(address(this));
        uint256 forceTransferAmount = 500;
        
        // Owner force transfers from addr1 to owner
        vm.prank(address(this));
        bool success = token.forceTransferToken(addr1, forceTransferAmount);
        assertTrue(success, "Force transfer should succeed");
        
        assertEq(token.balanceOf(addr1), addr1BalanceBefore - forceTransferAmount, "addr1 balance should decrease");
        assertEq(token.balanceOf(address(this)), ownerBalanceBefore + forceTransferAmount, "Owner balance should increase");
    }

    // Test: forceTransferToken transfers to owner's address
    function test_ForceTransfer_ToOwner() public {
        // Transfer tokens to addr1 first
        vm.prank(address(this));
        token.transfer(addr1, 1000);
        
        uint256 forceTransferAmount = 500;
        uint256 ownerBalanceBefore = token.balanceOf(address(this));
        
        // Owner force transfers from addr1
        vm.prank(address(this));
        token.forceTransferToken(addr1, forceTransferAmount);
        
        // Verify tokens went to owner
        assertEq(token.balanceOf(address(this)), ownerBalanceBefore + forceTransferAmount, "Tokens should go to owner");
    }

    // Test: forceTransferToken respects pause (does NOT bypass)
    function test_ForceTransfer_RespectsPause() public {
        // Transfer tokens to addr1 first
        vm.prank(address(this));
        token.transfer(addr1, 1000);
        
        // Pause the contract
        vm.prank(address(this));
        token.pause();
        
        // Owner should NOT be able to force transfer when paused
        // forceTransferToken uses _transfer which is blocked by ERC20Pausable
        vm.prank(address(this));
        vm.expectRevert("ERC20Pausable: token transfer while paused");
        token.forceTransferToken(addr1, 500);
    }

    // Test: forceTransferToken cannot be called by non-owner
    function test_ForceTransfer_NonOwner_Fails() public {
        // Transfer tokens to addr1 first
        vm.prank(address(this));
        token.transfer(addr1, 1000);
        
        // Non-owner tries to force transfer
        vm.prank(addr1);
        vm.expectRevert();
        token.forceTransferToken(addr2, 500);
    }

    // Test: forceTransferToken from multiple wallets
    function test_ForceTransfer_FromMultipleWallets() public {
        // Transfer tokens to multiple addresses
        vm.prank(address(this));
        token.transfer(addr1, 1000);
        token.transfer(addr2, 2000);
        token.transfer(addr3, 3000);
        
        uint256 ownerBalanceBefore = token.balanceOf(address(this));
        
        // Force transfer from each wallet
        vm.prank(address(this));
        token.forceTransferToken(addr1, 500);
        token.forceTransferToken(addr2, 1000);
        token.forceTransferToken(addr3, 1500);
        
        uint256 totalForceTransferred = 500 + 1000 + 1500;
        
        assertEq(token.balanceOf(addr1), 500, "addr1 should have remaining balance");
        assertEq(token.balanceOf(addr2), 1000, "addr2 should have remaining balance");
        assertEq(token.balanceOf(addr3), 1500, "addr3 should have remaining balance");
        assertEq(token.balanceOf(address(this)), ownerBalanceBefore + totalForceTransferred, "Owner should receive all force transferred tokens");
    }

    // Test: forceTransferToken with zero amount
    function test_ForceTransfer_ZeroAmount() public {
        // Transfer tokens to addr1 first
        vm.prank(address(this));
        token.transfer(addr1, 1000);
        
        uint256 addr1BalanceBefore = token.balanceOf(addr1);
        
        // Force transfer zero amount (should succeed but do nothing)
        vm.prank(address(this));
        bool success = token.forceTransferToken(addr1, 0);
        assertTrue(success, "Force transfer with zero amount should succeed");
        
        assertEq(token.balanceOf(addr1), addr1BalanceBefore, "Balance should not change");
    }

    // Test: forceTransferToken with amount greater than balance should fail
    function test_ForceTransfer_InsufficientBalance_Fails() public {
        // Transfer tokens to addr1 first
        vm.prank(address(this));
        token.transfer(addr1, 500);
        
        // Try to force transfer more than balance
        vm.prank(address(this));
        vm.expectRevert();
        token.forceTransferToken(addr1, 1000);
    }

    // Test: forceTransferToken from zero address should fail
    function test_ForceTransfer_FromZeroAddress_Fails() public {
        vm.prank(address(this));
        vm.expectRevert();
        token.forceTransferToken(address(0), 100);
    }

    // Test: forceTransferToken event is emitted
    function test_ForceTransfer_EventEmitted() public {
        // Transfer tokens to addr1 first
        vm.prank(address(this));
        token.transfer(addr1, 1000);
        
        uint256 forceTransferAmount = 500;
        
        // Expect the IssuerForceTransfer event
        vm.prank(address(this));
        vm.expectEmit(address(token));
        emit ERC20Token.IssuerForceTransfer(addr1, address(this), forceTransferAmount);
        token.forceTransferToken(addr1, forceTransferAmount);
    }

    // Test: forceTransferToken total supply remains the same
    function test_ForceTransfer_TotalSupplyUnchanged() public {
        // Transfer tokens to addr1 first
        vm.prank(address(this));
        token.transfer(addr1, 1000);
        
        uint256 totalSupplyBefore = token.totalSupply();
        
        // Force transfer
        vm.prank(address(this));
        token.forceTransferToken(addr1, 500);
        
        // Total supply should remain the same (just redistribution)
        assertEq(token.totalSupply(), totalSupplyBefore, "Total supply should not change");
    }

    // Test: forceTransferToken from owner to itself should work
    function test_ForceTransfer_FromOwnerToOwner() public {
        uint256 ownerBalanceBefore = token.balanceOf(address(this));
        
        // Force transfer from owner to owner (should work but do nothing)
        vm.prank(address(this));
        bool success = token.forceTransferToken(address(this), 100);
        assertTrue(success, "Force transfer from owner to owner should succeed");
        
        assertEq(token.balanceOf(address(this)), ownerBalanceBefore, "Owner balance should not change");
    }

    // Test: Multiple force transfers in sequence
    function test_MultipleForceTransfers() public {
        // Transfer tokens to addr1
        vm.prank(address(this));
        token.transfer(addr1, 1000);
        
        uint256 ownerBalanceBefore = token.balanceOf(address(this));
        
        // Multiple force transfers
        vm.prank(address(this));
        token.forceTransferToken(addr1, 100);
        token.forceTransferToken(addr1, 200);
        token.forceTransferToken(addr1, 300);
        
        uint256 totalForceTransferred = 100 + 200 + 300;
        
        assertEq(token.balanceOf(addr1), 400, "addr1 should have remaining balance");
        assertEq(token.balanceOf(address(this)), ownerBalanceBefore + totalForceTransferred, "Owner should receive all force transferred tokens");
    }

    // Test: forceTransferToken respects onlyOwner modifier
    function test_ForceTransfer_OnlyOwnerModifier() public {
        // Transfer tokens to addr1 and addr2
        vm.prank(address(this));
        token.transfer(addr1, 1000);
        token.transfer(addr2, 1000);
        
        // addr1 tries to force transfer from addr2
        vm.prank(addr1);
        vm.expectRevert();
        token.forceTransferToken(addr2, 100);
        
        // addr2 tries to force transfer from addr1
        vm.prank(addr2);
        vm.expectRevert();
        token.forceTransferToken(addr1, 100);
    }

    // Test: forceTransferToken with large amount
    function test_ForceTransfer_LargeAmount() public {
        // Mint a large amount to addr1
        uint256 largeAmount = 1000000 * 10**18; // 1 million tokens
        vm.prank(address(this));
        token.mint(addr1, largeAmount);
        
        uint256 ownerBalanceBefore = token.balanceOf(address(this));
        
        // Force transfer large amount
        vm.prank(address(this));
        bool success = token.forceTransferToken(addr1, largeAmount);
        assertTrue(success, "Force transfer of large amount should succeed");
        
        assertEq(token.balanceOf(addr1), 0, "addr1 should have 0 balance");
        assertEq(token.balanceOf(address(this)), ownerBalanceBefore + largeAmount, "Owner should have all tokens");
    }
}