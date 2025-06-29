// --------------------------------------------------------------------------------
// --------------------------------------------------------------------------------
// Test Suite 4  -   Test ERC20 related functonalities including address
// whitelistings
// --------------------------------------------------------------------------------
// --------------------------------------------------------------------------------

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/ERC1404TokenMinKYCv13.sol";
import "./helpers/ERC1404_Base_Setup.sol";

contract ERC1404_Basic_Transfer_Test is ERC1404_Base_Setup {
    uint _transferAmount = 100;
    int _transferNegativeAmount = -1;
    uint _transferAmountZero = 0;
    uint _transferMoreThanAvailable = initialSupply + 1;

    function setUp() public override {
        ERC1404_Base_Setup.setUp();
        token.modifyKYCData(addr1, 1, 1);
        token.modifyKYCData(addr2, 1, 1);
    }

    function testTransferAmount() public {
        token.transfer(addr1, _transferAmount);
        assertEq(token.balanceOf(addr1), _transferAmount);
        assertEq(
            token.balanceOf(token.owner()),
            initialSupply - _transferAmount
        );
    }

    function testIssuerTransferMoreThanAvailableAmount() public {
        vm.expectRevert("ERC20: transfer amount exceeds balance");
        token.transfer(addr1, _transferMoreThanAvailable);
    }

    function testInvestorTransferMoreThanAvailableAmount() public {
        token.transfer(addr1, _transferAmount);

        vm.prank(addr1);
        vm.expectRevert("ERC20: transfer amount exceeds balance");
        token.transfer(addr2, _transferAmount + 1);
    }

    function testTransferZeroAmount() public {
        vm.expectRevert("Zero transfer amount not allowed");
        token.transfer(addr1, _transferAmountZero);
    }

    function testTransferNegativeAmount() public {
        // Since the int type is not compatible with the uint type you cannot even try to test with negative values
        vm.expectRevert("ERC20: transfer amount exceeds balance");
        token.transfer(addr1, uint(_transferNegativeAmount));
    }

    function testFailTransferOverflowAmount() public {
        token.transfer(addr1, uint(_transferNegativeAmount) + 1);
    }

    function testTransferFromInvestorToInvestor() public {
        token.transfer(addr1, _transferAmount);

        vm.prank(addr1);
        token.transfer(addr2, _transferAmount);
        assertEq(token.balanceOf(addr2), _transferAmount);
        assertEq(token.balanceOf(addr1), 0);
    }
}
