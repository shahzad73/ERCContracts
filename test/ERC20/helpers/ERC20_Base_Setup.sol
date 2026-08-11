// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../../../src/ERC20Token.sol";

contract ERC20_Base_Setup is Test {
    address addr1 = 0x1a8929fbE9abEc00CDfCda8907408848cBeb5300;
    address addr2 = 0xAD3DF0f1c421002B8Eff81288146AF9bC692d13d;
    address addr3 = 0x8192706d699390D668710BD247886e3016D4672E;
    address addr4 = 0x6a44140c28629b1E20114122fb53101dB6953efC;

    ERC20Token token;
    string name = "TestToken";
    uint256 initialSupply = 10000;
    uint8 decimalsPlaces = 18;

    function setUp() public virtual {
        token = new ERC20Token(initialSupply, name);
    }
}