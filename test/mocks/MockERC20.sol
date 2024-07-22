// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.16;

import {ERC20Permit, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract MockERC20 is ERC20Permit {
    constructor() ERC20Permit("Random") ERC20("MockERC20", "ME20") {
        uint256 amount = 1 * 10 ** 9 * 10 ** 18;
        _mint(msg.sender, amount);
    }
}
