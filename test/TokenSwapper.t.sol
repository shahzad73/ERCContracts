// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import "ds-test/test.sol";
import { TokenSwapper } from "../src/Erc20_swapper_V4.sol";
import { ERC1404TokenMinKYCv13 } from "../src/ERC1404TokenMinKYCv13.sol";
import "forge-std/console.sol";

// This is an example of how to write tests for solidity
// Pay attention to the file name (.t.sol is used in order to recognize which files are meant for tests)

interface Vm {
    // you can use this to test fail cases from require or revert reasons
    function expectRevert(bytes calldata) external;
    // use this to call contracts from different addresses for the next 1 call
    function prank(address) external;

    // use this to call contracts from a different address until the stopPrank function is called
    function startPrank(address) external;
    // use this to stop the chain of pranks
    function stopPrank() external;

    function warp(uint256) external;    
}

interface CheatCodes {
    // Gets address for a given private key, (privateKey) => (address)
    function addr(uint256) external returns (address);
}

// if you need to use structs, you can import them through inheritance (in this case TokenSwapper's Swap struct)
contract TokenSwapperTest is DSTest, TokenSwapper {
    Vm _vm = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
    CheatCodes _cheats = CheatCodes(HEVM_ADDRESS);
    address public addr1;
    address public addr2;

    TokenSwapper _swapper;
    ERC1404TokenMinKYCv13 _token1;
    ERC1404TokenMinKYCv13 _token2;
    uint _amount1 = 100;
    uint _amount2 = 200;

    // setUp will be run before any tests
    function setUp() public {
        addr1 = _cheats.addr(1);
        addr2 = _cheats.addr(2);
        uint64 limitInvestors = 0;
        _swapper = new TokenSwapper();
        _token1 = new ERC1404TokenMinKYCv13(1000, '_token1', 'TKN1', limitInvestors, 0, 'share certificate', 'company homepage', 'company legal docs', address(_swapper), 1);
        _token2 = new ERC1404TokenMinKYCv13(1000, '_token2', 'TKN2', limitInvestors, 0, 'share certificate', 'company homepage', 'company legal docs', address(_swapper), 1);

        _token1.modifyKYCData(address(_swapper), 1, 1);
        _token1.modifyKYCData(addr1, 1, 1);
        _token1.modifyKYCData(addr2, 1, 1);
        _token1.mint(addr1, _amount1);

        _token2.modifyKYCData(address(_swapper), 1, 1);
        _token2.modifyKYCData(addr1, 1, 1);
        _token2.modifyKYCData(addr2, 1, 1);
        _token2.mint(addr2, _amount2);
    }

    function testswaptokeentotalsupply () public {
        // check total supply and balance of test accounts 

        assertEq( _token1.totalSupply(), 1100);
        assertEq( _token2.totalSupply(), 1200 );

        assertEq( _token1.balanceOf(addr1), 100 );
        assertEq( _token1.balanceOf(addr2), 0 );
        assertEq( _token1.balanceOf(address(_swapper)), 0 );        

        assertEq( _token2.balanceOf(addr1), 0 );
        assertEq( _token2.balanceOf(addr2), 200 );        
        assertEq( _token2.balanceOf(address(_swapper)), 0 );        

    }

    function testswapisopenandvalidafteropening() public {
        // addr1 opens the swap with 10 tokens offer against 100 tokens         
        _vm.startPrank(addr1);
        _token1.approve(address(_swapper), 10);
        assertEq( _token1.allowance(addr1, address(_swapper)), 10 );
        _swapper.open(2, addr2, address(_token1), 10, address(_token2), 100, 100);
        _vm.stopPrank();  

        (Swap memory result, uint status) = _swapper.getSwapData(addr1, 2);
        console.log(result.expiry);
        assertEq( status, 1 );
    }

    function testswapbetweentoken1token2() public {
        // addr1 will give 50 token 1     from    100 addr2 

        uint swapNumber = 3;
        uint expiry = 100;

        // addr1 opens the swap with 10 tokens offer against 100 tokens         
        _vm.startPrank(addr1);
        _token1.approve(address(_swapper), 10);
        assertEq( _token1.allowance(addr1, address(_swapper)), 10 );
        _swapper.open(swapNumber, addr2, address(_token1), 10, address(_token2), 100, expiry);
        _vm.stopPrank();        

        (Swap memory result2, uint status2) = _swapper.getSwapData(addr1, swapNumber);
        assertEq( status2, 1 );
        console.log(result2.expiry);

        // addr2 closes the deal giving 100 tokens and receiving 10 tokens
        _vm.startPrank(addr2);
        _token2.approve(address(_swapper), 100);
        assertEq( _token2.allowance(addr2, address(_swapper)), 100 );
        _swapper.close(addr1, swapNumber);
        _vm.stopPrank();        

        assertEq( _token1.balanceOf(addr1), 90 );  
        assertEq( _token2.balanceOf(addr1), 100 );  

        assertEq( _token1.balanceOf(addr2), 10 );  
        assertEq( _token2.balanceOf(addr2), 100 );  

        (Swap memory result, uint status) = _swapper.getSwapData(addr1, swapNumber);
        console.log(result.expiry);
        assertEq( status, 2 );
    }

    function testswapcanbeclosedmultipletimes() public {

        uint swapNumber = 4;
        uint expiry = 100;

        // addr1 opens the swap with 10 tokens offer against 100 tokens         
        _vm.startPrank(addr1);
        _token1.approve(address(_swapper), 10);
        assertEq( _token1.allowance(addr1, address(_swapper)), 10 );
        _swapper.open(swapNumber, addr2, address(_token1), 10, address(_token2), 100, expiry);
        _vm.stopPrank();        

        // addr2 closes the deal giving 100 tokens and receiving 10 tokens
        _vm.startPrank(addr2);
        _token2.approve(address(_swapper), 100);
        assertEq( _token2.allowance(addr2, address(_swapper)), 100 );
        _swapper.close(addr1, swapNumber);
        _vm.stopPrank();        

        assertEq( _token1.balanceOf(addr1), 90 );  
        assertEq( _token2.balanceOf(addr1), 100 );  

        assertEq( _token1.balanceOf(addr2), 10 );  
        assertEq( _token2.balanceOf(addr2), 100 );  

        // try to close swap again and catch error
        _vm.startPrank(addr2);
        _vm.expectRevert ("Token_swapper: swap not open");      
        _swapper.close(addr1, swapNumber);
        _vm.stopPrank(); 
    }

    function testswapnumberalreadytaken() public {
        // addr1 opens the swap with 10 tokens offer against 100 tokens         
        _vm.startPrank(addr1);
        _token1.approve(address(_swapper), 10);
        assertEq( _token1.allowance(addr1, address(_swapper)), 10 );
        _swapper.open(5, addr2, address(_token1), 10, address(_token2), 100, 100);
        _vm.stopPrank();  

        (Swap memory result, uint status) = _swapper.getSwapData(addr1, 5);
        console.log(result.expiry);
        assertEq( status, 1 );


        _vm.startPrank(addr1);
        _token1.approve(address(_swapper), 10);
        assertEq( _token1.allowance(addr1, address(_swapper)), 10 );
        _vm.expectRevert ("Token_swapper: swapNumber already used");      
        _swapper.open(5, addr2, address(_token1), 10, address(_token2), 100, 100);
        _vm.stopPrank();
    }

    function testswapexpireclosefailure() public {

        uint swapNumber = 10;

        // addr1 opens the swap with 10 tokens offer against 100 tokens         
        _vm.startPrank(addr1);
        _token1.approve(address(_swapper), 10);
        assertEq( _token1.allowance(addr1, address(_swapper)), 10 );
        _swapper.open(swapNumber, addr2, address(_token1), 10, address(_token2), 100, 100);
        _vm.stopPrank();  

        (Swap memory result, uint status) = _swapper.getSwapData(addr1, swapNumber);
        console.log(result.expiry);
        assertEq( status, 1 );

        // print current timestamp
        // emit log_uint(block.timestamp); 
        _vm.warp(1000);

        _vm.startPrank(addr2);
        _token2.approve(address(_swapper), 100);
        assertEq( _token2.allowance(addr2, address(_swapper)), 100 );
        _vm.expectRevert("Token_swapper: swap expiration passed");
        _swapper.close(addr1, swapNumber);
        _vm.stopPrank();  

    }

    function testexpireandtakebacktokens() public {

        uint swapNumber = 11;

        // addr1 opens the swap with 10 tokens offer against 100 tokens         
        _vm.startPrank(addr1);
        _token1.approve(address(_swapper), 10);
        assertEq( _token1.allowance(addr1, address(_swapper)), 10 );
        _swapper.open(swapNumber, addr2, address(_token1), 10, address(_token2), 100, 100);
        _vm.stopPrank();  

        (Swap memory result, uint status) = _swapper.getSwapData(addr1, swapNumber);
        console.log(result.expiry);
        assertEq( status, 1 );

        // print current timestamp
        // emit log_uint(block.timestamp); 
        _vm.warp(1000);

        assertEq( _token1.balanceOf(addr1), 90 );
        assertEq( _token1.balanceOf(address(_swapper)), 10 );                

        _vm.startPrank(addr1);
        _swapper.expire(addr1, swapNumber);
        _vm.stopPrank();  


        assertEq( _token1.totalSupply(), 1100);
        assertEq( _token2.totalSupply(), 1200 );

        assertEq( _token1.balanceOf(addr1), 100 );
        assertEq( _token1.balanceOf(addr2), 0 );
        assertEq( _token1.balanceOf(address(_swapper)), 0 );        

        assertEq( _token2.balanceOf(addr1), 0 );
        assertEq( _token2.balanceOf(addr2), 200 );        
        assertEq( _token2.balanceOf(address(_swapper)), 0 );   

    }    

}

