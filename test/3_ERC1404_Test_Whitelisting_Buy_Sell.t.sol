// --------------------------------------------------------------------------------
// --------------------------------------------------------------------------------
// Test Suite 3   -   Test EPOCH times in whitelisting.  Test both buy and sell restrictions
// --------------------------------------------------------------------------------
// --------------------------------------------------------------------------------

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/ERC1404TokenMinKYCv13.sol";
import "./helpers/ERC1404_Base_Setup.sol";

contract ERC1404_Test_Whitelisting_Buy_Sell is ERC1404_Base_Setup {
    uint _transferAmount = 100;

    function setUp() public override {
        ERC1404_Base_Setup.setUp();
        token.modifyKYCData(addr1, 1, 1);
    }

    function testSetWhitelistKYCInformation() public {
        token.modifyKYCData(addr2, 500, 500);
        (uint receiveRestriction, uint sendRestriction) = token.getKYCData(
            addr2
        );
        assertEq(receiveRestriction, 500);
        assertEq(sendRestriction, 500);
    }

    function testTokensCannotBeTransferredToNonWhitelistedAddress()
        public
    {
        // is not whitelisted and this call will fail
        vm.expectRevert("Receiver is not whitelisted or blocked");
        token.transfer(addr2, _transferAmount);
    }

    function testTokensCannotBeMintedToNonWhitelistedAddress() public {
        // is not whitelisted and this call will fail
        vm.expectRevert("Address is not yet whitelisted by issuer");
        token.mint(addr2, _transferAmount);
    }

    function testTokensCannotBeTransferredFromNonWhitelistedAddress()
        public
    {
        // is not whitelisted and this call will fail
        vm.prank(addr2);
        vm.expectRevert("Sender is not whitelisted or blocked");
        token.transfer(addr3, _transferAmount);
    }

    function testTokensSendRestriction() public {
        token.modifyKYCData(addr2, 1, EPOCHTimeInFuture);
        vm.prank(addr2);
        vm.expectRevert(
            "Sender is whitelisted but is not eligible to send tokens and under holding period (KYC time restriction)"
        );
        token.transfer(addr1, _transferAmount);
    }

    function testTokensReceiveRestrictionTransfer() public {
        token.modifyKYCData(addr2, EPOCHTimeInFuture, EPOCHTimeInFuture);
        vm.expectRevert(
            "Receiver is whitelisted but is not yet eligible to receive tokens in his wallet (KYC time restriction)"
        );
        token.transfer(addr2, _transferAmount);
    }

    // This should most likely revert but does not
    function testTokensReceiveRestrictionMintReceiveRestricted() public {
        token.modifyKYCData(addr2, EPOCHTimeInFuture, EPOCHTimeInFuture);
        token.mint(addr2, _transferAmount);
    }

    function testTokensReceiveRestrictionMintNotWhitelisted() public {
        vm.expectRevert("Address is not yet whitelisted by issuer");
        token.mint(addr2, _transferAmount);
    }

    function testCurrentTotalInvestorsIncreaseTransfer() public {
        token.transfer(addr1, _transferAmount);
        assertEq(token.currentTotalInvestors(), 1);
    }

    function testCurrentTotalInvestorsIncreaseMint() public {
        token.mint(addr1, _transferAmount);
        assertEq(token.currentTotalInvestors(), 1);
    }

    function testCurrentTotalInvestorsDecrease() public {
        token.transfer(addr1, _transferAmount);
        address owner = token.owner();
        vm.prank(addr1);
        token.transfer(owner, _transferAmount);
        assertEq(token.currentTotalInvestors(), 0);
    }

    function testBurnToDecreaseTotalInvestors(uint8 amount) public {
        vm.assume(amount > 0);
        token.mint(addr1, amount);
        token.burn(addr1, amount);
        assertEq(token.currentTotalInvestors(), 0);
    }
}
