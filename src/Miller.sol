// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

error RecipientRevert();

contract Miller is Context {
    event Distribute(address initiator);

    using SafeERC20 for IERC20;

    struct DistributionConfig {
        uint240 amount;
        address to;
    }

    function distribute(DistributionConfig[] calldata config) external returns (bool) {
        for (uint256 i = 0; i < config.length; i++) {
            _withdrawNative(payable(config[i].to), config[i].amount);
        }
        emit Distribute(_msgSender());
        return true;
    }

    function distributeFixed(uint240 amount, address[] calldata to) external returns (bool) {
        for (uint256 i = 0; i < to.length; i++) {
            _withdrawNative(payable(to[i]), amount);
        }
        emit Distribute(_msgSender());
        return true;
    }

    function _withdrawNative(address payable to, uint240 amount) private {
        (bool success,) = to.call{value: amount}("");
        if (!success) {
            revert RecipientRevert();
        }
    }

    function distributeERC20(
        DistributionConfig[] calldata config,
        address token,
        uint240 permitAmount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public returns (bool) {
        // Skip ddos transactions
        // We are not needed in either catching the error or implementing
        // a success flow. In case of error, we let safeTransferFrom revert
        try IERC20Permit(token).permit(_msgSender(), address(this), permitAmount, deadline, v, r, s)
        {} catch {}

        for (uint256 i = 0; i < config.length; i++) {
            _withdrawERC20(config[i].to, IERC20(token), config[i].amount);
        }
        emit Distribute(_msgSender());

        return true;
    }

    function distributeERC20Fixed(
        uint240 amount,
        address[] calldata to,
        address token,
        uint240 permitAmount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public returns (bool) {
        // Skip ddos transactions
        // We are not needed in either catching the error or implementing
        // a success flow. In case of error, we let safeTransferFrom revert
        try IERC20Permit(token).permit(_msgSender(), address(this), permitAmount, deadline, v, r, s)
        {} catch {}

        for (uint256 i = 0; i < to.length; i++) {
            _withdrawERC20(to[i], IERC20(token), amount);
        }
        emit Distribute(_msgSender());

        return true;
    }

    function _withdrawERC20(address to, IERC20 erc20token, uint240 amount) private {
        erc20token.safeTransfer(to, amount);
    }
}
