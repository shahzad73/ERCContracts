// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";

contract Global_Helpers is Test {
    bytes32 internal nextUser = keccak256(abi.encodePacked("user address"));

    function getNextUserAddress() external returns (address payable) {
        address payable user = payable(address(uint160(uint256(nextUser))));
        nextUser = keccak256(abi.encodePacked(nextUser));
        return user;
    }

    // create users with 100 ETH balance each
    function createUsers(
        uint256 userNum
    ) external returns (address payable[] memory) {
        address payable[] memory users = new address payable[](userNum);
        for (uint256 i = 0; i < userNum; i++) {
            address payable user = this.getNextUserAddress();
            vm.deal(user, 100 ether);
            users[i] = user;
        }

        return users;
    }

    // create amounts with totalAmount
    function createAmounts(
        uint userNum
    ) external pure returns (uint[] memory, uint) {
        uint totalAmount = 0;
        uint[] memory amounts = new uint[](userNum);
        for (uint256 i = 0; i < userNum; i++) {
            amounts[i] = i + 20;
            totalAmount += amounts[i];
        }

        return (amounts, totalAmount);
    }

    //move block.number forward by a given number of blocks
    function mineBlocks(uint256 numBlocks) external {
        uint256 targetBlock = block.number + numBlocks;
        vm.roll(targetBlock);
    }
}
