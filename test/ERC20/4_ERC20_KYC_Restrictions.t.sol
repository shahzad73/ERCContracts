// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "./helpers/ERC20_Base_Setup.sol";
import "forge-std/Test.sol";

contract ERC20_KYC_Restrictions_Test is ERC20_Base_Setup {
    // Test 1: By default users are allowed to send and receive tokens
    function test_Default_NoRestrictions() public {
        // Transfer some tokens to addr1
        vm.prank(address(this));
        token.transfer(addr1, 1000);
        
        // addr1 should be able to send to addr2 (both have default 0 restrictions)
        vm.prank(addr1);
        bool success = token.transfer(addr2, 100);
        assertTrue(success, "Transfer should succeed with default settings");
        
        assertEq(token.balanceOf(addr2), 100, "addr2 should receive tokens");
    }

    // Test 2: If sender has sendRestriction in future, cannot send tokens
    function test_SenderWithFutureRestriction_CannotSend() public {
        // Set send restriction for addr1 to 1 year in future
        uint256 futureTime = block.timestamp + 365 days;
        vm.prank(address(this));
        token.modifyKYCData(addr1, 0, futureTime);
        
        // Transfer some tokens to addr1
        vm.prank(address(this));
        token.transfer(addr1, 1000);
        
        // addr1 should NOT be able to send tokens
        vm.prank(addr1);
        vm.expectRevert("Sender is under send restrictions");
        token.transfer(addr2, 100);
    }

    // Test 3: If receiver has receiveRestriction in future, cannot receive tokens
    function test_ReceiverWithFutureRestriction_CannotReceive() public {
        // Set receive restriction for addr2 to 1 year in future
        uint256 futureTime = block.timestamp + 365 days;
        vm.prank(address(this));
        token.modifyKYCData(addr2, futureTime, 0);
        
        // addr1 should NOT be able to send to addr2
        vm.prank(address(this));
        vm.expectRevert("Receiver is under receive restriction");
        token.transfer(addr2, 100);
    }

    // Test 4a: Both sender and receiver have restrictions - sender cannot send
    function test_BothHaveRestrictions_SenderCannotSend() public {
        uint256 futureTime = block.timestamp + 365 days;
        
        // Set both restrictions
        vm.prank(address(this));
        token.modifyKYCData(addr1, 0, futureTime); // addr1 cannot send
        token.modifyKYCData(addr2, futureTime, 0); // addr2 cannot receive
        
        // Transfer some tokens to addr1
        vm.prank(address(this));
        token.transfer(addr1, 1000);
        
        // addr1 should NOT be able to send (sender restriction)
        vm.prank(addr1);
        vm.expectRevert("Sender is under send restrictions");
        token.transfer(addr2, 100);
    }

    // Test 4b: Both sender and receiver have restrictions - receiver cannot receive
    function test_BothHaveRestrictions_ReceiverCannotReceive() public {
        uint256 futureTime = block.timestamp + 365 days;
        
        // Set both restrictions
        vm.prank(address(this));
        token.modifyKYCData(addr1, futureTime, 0); // addr1 cannot receive
        token.modifyKYCData(addr2, 0, futureTime); // addr2 cannot send
        
        // addr1 should NOT be able to receive from addr2 (receiver restriction)
        vm.prank(address(this));
        vm.expectRevert("Receiver is under receive restriction");
        token.transfer(addr1, 100);
    }

    // Test 4c: Sender restriction expired, receiver restriction active
    function test_SenderRestrictionExpired_ReceiverRestrictionActive() public {
        // Set addr1 send restriction to past (expired) - use safe subtraction
        uint256 pastTime = block.timestamp > 365 days ? block.timestamp - 365 days : 0;
        // Set addr2 receive restriction to future
        uint256 futureTime = block.timestamp + 365 days;
        
        vm.prank(address(this));
        token.modifyKYCData(addr1, 0, pastTime); // addr1 can send (expired)
        token.modifyKYCData(addr2, futureTime, 0); // addr2 cannot receive
        
        // Transfer some tokens to addr1
        vm.prank(address(this));
        bool success = token.transfer(addr1, 1000);
        assertTrue(success, "Transfer to addr1 should succeed");
        
        // addr1 should NOT be able to send to addr2 (receiver restriction)
        vm.prank(addr1);
        vm.expectRevert("Receiver is under receive restriction");
        token.transfer(addr2, 100);
    }

    // Test 4d: Sender restriction active, receiver restriction expired
    function test_SenderRestrictionActive_ReceiverRestrictionExpired() public {
        // Set addr1 send restriction to future
        uint256 futureTime = block.timestamp + 365 days;
        // Set addr2 receive restriction to past (expired) - use safe subtraction
        uint256 pastTime = block.timestamp > 365 days ? block.timestamp - 365 days : 0;
        
        vm.prank(address(this));
        token.modifyKYCData(addr1, 0, futureTime); // addr1 cannot send
        token.modifyKYCData(addr2, pastTime, 0); // addr2 can receive (expired)
        
        // Transfer some tokens to addr1
        vm.prank(address(this));
        bool success = token.transfer(addr1, 1000);
        assertTrue(success, "Transfer to addr1 should succeed");
        
        // addr1 should NOT be able to send (sender restriction)
        vm.prank(addr1);
        vm.expectRevert("Sender is under send restrictions");
        token.transfer(addr2, 100);
    }

    // Test 4e: Both restrictions expired - transfer should work
    function test_BothRestrictionsExpired_TransferSucceeds() public {
        // Set both restrictions to past (expired) - use safe subtraction
        uint256 pastTime = block.timestamp > 365 days ? block.timestamp - 365 days : 0;
        
        vm.prank(address(this));
        token.modifyKYCData(addr1, pastTime, pastTime);
        token.modifyKYCData(addr2, pastTime, pastTime);
        
        // Transfer some tokens to addr1
        vm.prank(address(this));
        bool success = token.transfer(addr1, 1000);
        assertTrue(success, "Transfer to addr1 should succeed");
        
        // addr1 should be able to send to addr2 (both restrictions expired)
        vm.prank(addr1);
        success = token.transfer(addr2, 100);
        assertTrue(success, "Transfer should succeed when both restrictions expired");
        
        assertEq(token.balanceOf(addr2), 100, "addr2 should receive tokens");
    }

    // Test 5: Set wallet to far future (2-3 centuries) - cannot send or receive
    function test_FarFutureRestriction_CannotSendOrReceive() public {
        // Set restriction to far future
        uint256 farFuture = block.timestamp + 10000 days;
        
        vm.prank(address(this));
        token.modifyKYCData(addr1, farFuture, farFuture);
        
        // addr1 should NOT be able to receive tokens via normal transfer
        vm.prank(address(this));
        vm.expectRevert("Receiver is under receive restriction");
        token.transfer(addr1, 100);
        
        // To test sending, we need to give addr1 tokens first
        // Temporarily remove restrictions, transfer tokens, then reapply restrictions
        vm.prank(address(this));
        token.modifyKYCData(addr1, 0, 0); // Remove restrictions
        
        // Transfer tokens to addr1
        vm.prank(address(this));
        token.transfer(addr1, 1000);
        
        // Reapply restrictions
        vm.prank(address(this));
        token.modifyKYCData(addr1, farFuture, farFuture);
        
        // Now addr1 should NOT be able to send
        vm.prank(addr1);
        vm.expectRevert("Sender is under send restrictions");
        token.transfer(addr2, 100);
    }

    // Test: Owner can modify KYC data
    function test_OwnerCanModifyKYCData() public {
        uint256 futureTime = block.timestamp + 365 days;
        
        vm.prank(address(this));
        token.modifyKYCData(addr1, futureTime, futureTime);
        
        (uint256 receiveRestriction, uint256 sendRestriction) = token.getKYCData(addr1);
        assertEq(receiveRestriction, futureTime, "Receive restriction should be set");
        assertEq(sendRestriction, futureTime, "Send restriction should be set");
    }

    // Test: Non-owner cannot modify KYC data
    function test_NonOwnerCannotModifyKYCData() public {
        uint256 futureTime = block.timestamp + 365 days;
        
        vm.prank(addr1);
        vm.expectRevert();
        token.modifyKYCData(addr2, futureTime, futureTime);
    }

    // Test: Cannot modify KYC data for zero address
    function test_ModifyKYCData_ZeroAddress_Fails() public {
        uint256 futureTime = block.timestamp + 365 days;
        
        vm.prank(address(this));
        vm.expectRevert();
        token.modifyKYCData(address(0), futureTime, futureTime);
    }

    // Test: KYC event is emitted
    function test_KYCData_EventEmitted() public {
        uint256 futureTime = block.timestamp + 365 days;
        
        vm.prank(address(this));
        vm.expectEmit(address(token));
        emit ERC20Token.KYCDataForUserSet(addr1, futureTime, futureTime);
        token.modifyKYCData(addr1, futureTime, futureTime);
    }

    // Test: Transfer with transferFrom respects KYC restrictions
    function test_TransferFrom_RespectsKYCRestrictions() public {
        uint256 futureTime = block.timestamp + 365 days;
        
        // Set send restriction for owner
        vm.prank(address(this));
        token.modifyKYCData(address(this), 0, futureTime);
        
        // Approve addr1
        vm.prank(address(this));
        token.approve(addr1, 100);
        
        // addr1 should NOT be able to transferFrom owner (owner has send restriction)
        vm.prank(addr1);
        vm.expectRevert("Sender is under send restrictions");
        token.transferFrom(address(this), addr2, 100);
    }

    // Test: getKYCData returns correct values
    function test_GetKYCData() public {
        uint256 receiveRestriction = block.timestamp + 365 days;
        uint256 sendRestriction = block.timestamp + 730 days;
        
        vm.prank(address(this));
        token.modifyKYCData(addr1, receiveRestriction, sendRestriction);
        
        (uint256 receivedReceive, uint256 receivedSend) = token.getKYCData(addr1);
        assertEq(receivedReceive, receiveRestriction, "Receive restriction should match");
        assertEq(receivedSend, sendRestriction, "Send restriction should match");
    }

    // Test: getKYCData for address with no restrictions
    function test_GetKYCData_NoRestrictions() public {
        (uint256 receiveRestriction, uint256 sendRestriction) = token.getKYCData(addr1);
        assertEq(receiveRestriction, 0, "Receive restriction should be 0");
        assertEq(sendRestriction, 0, "Send restriction should be 0");
    }
}