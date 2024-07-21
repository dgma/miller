// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.16;

// solhint-disable no-global-import
// solhint-disable no-console

import "@std/Test.sol";

import {Miller} from "src/Miller.sol";

contract MillerTest is Test {
    Miller private miller;

    function setUp() public {
        miller = new Miller();
    }
}
