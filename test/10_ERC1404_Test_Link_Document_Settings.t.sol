// --------------------------------------------------------------------------------
// --------------------------------------------------------------------------------
// Test Suite 10   -  Test Token Links and Document information management
// --------------------------------------------------------------------------------
// --------------------------------------------------------------------------------

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/ERC1404TokenMinKYCv13.sol";
import "./helpers/ERC1404_Base_Setup.sol";

contract ERC1404_Test_Link_Document_Settings is ERC1404_Base_Setup {
    function setUp() public override {
        ERC1404_Base_Setup.setUp();
    }

    function testResetShareCertificate() public {
        token.resetShareCertificate("New Share Certificate Link");
        string memory s = token.ShareCertificate();
        assertEq(s, "New Share Certificate Link");
    }

    function testCheckResetShareCertificateOnlyOwner() public {
        vm.prank(addr1);
        vm.expectRevert("Ownable: caller is not the owner");
        token.resetShareCertificate("New Share Certificate Link");
    }

    function testResetCompanyHomepage() public {
        token.resetCompanyHomepage("New Company Home Page Link");
        string memory s = token.CompanyHomepage();
        assertEq(s, "New Company Home Page Link");
    }

    function testCheckResetCompanyHomepageOnlyOwner() public {
        vm.prank(addr1);
        vm.expectRevert("Ownable: caller is not the owner");
        token.resetCompanyHomepage("New Company Home Page Link");
    }

    function testResetCompanyLegalDocs() public {
        token.resetCompanyLegalDocs("New Company Legal Documents Link");
        string memory s = token.CompanyLegalDocs();
        assertEq(s, "New Company Legal Documents Link");
    }

    function testCheckResetCompanyLegalDocsOnlyOwner() public {
        vm.prank(addr1);
        vm.expectRevert("Ownable: caller is not the owner");
        token.resetCompanyLegalDocs("New Company Legal Documents Link");
    }
}
