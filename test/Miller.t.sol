// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.16;

// solhint-disable no-global-import
// solhint-disable no-console

import "@std/Test.sol";

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Miller} from "src/Miller.sol";

contract MillerTest is Test {
    Miller private miller;

    address private alice = makeAddr("alice");

    function setUp() public {
        miller = new Miller();
        vm.deal(alice, 10 ether);
    }

    function generateAccounts(uint8 amount) private returns (address[] memory) {
        address[] memory addressList = new address[](amount);
        for (uint256 i = 0; i < addressList.length; i++) {
            addressList[i] = makeAddr(Strings.toString(i * 20));
        }
        return addressList;
    }

    function testFuzz_distributeFixed(uint8 addressesAmount, uint32 amountToDistribute) public {
        vm.assume(addressesAmount > 0);
        uint240 totalDistribute = uint240(amountToDistribute) * uint240(addressesAmount);
        address[] memory addressList = generateAccounts(addressesAmount);
        console.log("address %s", addressList[0]);
        vm.prank(alice);
        miller.distributeFixed{value: totalDistribute}(uint240(amountToDistribute), addressList);
        assertEq(alice.balance, 10 ether - uint256(totalDistribute));
        for (uint256 i = 0; i < addressList.length; i++) {
            assertEq(addressList[i].balance, amountToDistribute);
        }
    }
}
