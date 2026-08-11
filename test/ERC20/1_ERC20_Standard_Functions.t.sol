// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "./helpers/ERC20_Base_Setup.sol";
import "forge-std/Test.sol";

contract ERC20_Standard_Functions_Test is ERC20_Base_Setup {
    // Test totalSupply()
    function test_TotalSupply() public {
        uint256 totalSupply = token.totalSupply();
        assertEq(totalSupply, initialSupply, "Total supply should match initial supply");
    }

    // Test balanceOf()
    function test_BalanceOf() public {
        uint256 ownerBalance = token.balanceOf(address(this));
        assertEq(ownerBalance, initialSupply, "Owner should have initial supply");
        
        uint256 zeroBalance = token.balanceOf(address(0));
        assertEq(zeroBalance, 0, "Zero address should have 0 balance");
    }

    // Test transfer()
    function test_Transfer() public {
        uint256 transferAmount = 100;
        uint256 ownerBalanceBefore = token.balanceOf(address(this));
        uint256 recipientBalanceBefore = token.balanceOf(addr1);
        
        vm.prank(address(this));
        bool success = token.transfer(addr1, transferAmount);
        assertTrue(success, "Transfer should succeed");
        
        assertEq(token.balanceOf(address(this)), ownerBalanceBefore - transferAmount, "Owner balance should decrease");
        assertEq(token.balanceOf(addr1), recipientBalanceBefore + transferAmount, "Recipient balance should increase");
    }

    // Test transfer() to zero address should fail
    function test_Transfer_ToZeroAddress_Fails() public {
        vm.prank(address(this));
        vm.expectRevert();
        token.transfer(address(0), 100);
    }

    // Test transfer() with insufficient balance should fail
    function test_Transfer_InsufficientBalance_Fails() public {
        vm.prank(addr1);
        vm.expectRevert();
        token.transfer(addr2, 100);
    }

    // Test allowance()
    function test_Allowance() public {
        uint256 allowanceAmount = 500;
        
        vm.prank(address(this));
        token.approve(addr1, allowanceAmount);
        
        uint256 allowance = token.allowance(address(this), addr1);
        assertEq(allowance, allowanceAmount, "Allowance should match approved amount");
    }

    // Test approve()
    function test_Approve() public {
        uint256 approveAmount = 500;
        
        vm.prank(address(this));
        bool success = token.approve(addr1, approveAmount);
        assertTrue(success, "Approve should succeed");
        
        assertEq(token.allowance(address(this), addr1), approveAmount, "Allowance should be set");
    }

    // Test approve() to zero spender should fail
    function test_Approve_ZeroSpender_Fails() public {
        vm.prank(address(this));
        vm.expectRevert("ERC20: approve to the zero address");
        token.approve(address(0), 500);
    }

    // Test transferFrom()
    function test_TransferFrom() public {
        uint256 transferAmount = 100;
        
        // First approve addr1 to spend tokens
        vm.prank(address(this));
        token.approve(addr1, transferAmount);
        
        uint256 ownerBalanceBefore = token.balanceOf(address(this));
        uint256 recipientBalanceBefore = token.balanceOf(addr2);
        
        // Then transfer from owner to addr2 using addr1
        vm.prank(addr1);
        bool success = token.transferFrom(address(this), addr2, transferAmount);
        assertTrue(success, "transferFrom should succeed");
        
        assertEq(token.balanceOf(address(this)), ownerBalanceBefore - transferAmount, "Owner balance should decrease");
        assertEq(token.balanceOf(addr2), recipientBalanceBefore + transferAmount, "Recipient balance should increase");
    }

    // Test transferFrom() with insufficient allowance should fail
    function test_TransferFrom_InsufficientAllowance_Fails() public {
        vm.prank(address(this));
        token.approve(addr1, 50);
        
        vm.prank(addr1);
        vm.expectRevert();
        token.transferFrom(address(this), addr2, 100);
    }

    // Test transferFrom() with insufficient balance should fail
    function test_TransferFrom_InsufficientBalance_Fails() public {
        vm.prank(addr1);
        vm.expectRevert();
        token.transferFrom(address(this), addr2, 100);
    }

    // Test name()
    function test_Name() public {
        assertEq(token.name(), name, "Token name should match");
    }

    // Test symbol()
    function test_Symbol() public {
        assertEq(token.symbol(), name, "Token symbol should match name");
    }

    // Test decimals()
    function test_Decimals() public {
        assertEq(token.decimals(), 18, "Token decimals should be 18");
    }
}