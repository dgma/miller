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

    /// @notice Distributes received ETH to addresses according to configuration
    /// @dev Atomic execution. Contract will revert all distribution if any withdrawal fails
    /// @param config - The list of struct defines how many ETH (amount, wei) and to whom (to)
    /// should be distributed
    function distribute(DistributionConfig[] calldata config) external payable {
        for (uint256 i = 0; i < config.length; i++) {
            _withdrawNative(payable(config[i].to), config[i].amount);
        }
        emit Distribute(_msgSender());
    }

    /// @notice Distributes received ETH to addresses
    /// @dev Atomic execution. Contract will revert all distribution if any withdrawal fails
    /// @param amount - How many ETH (wie) should be distributed to each address
    /// @param to - The recipient's address list
    function distributeFixed(uint240 amount, address[] calldata to) external payable {
        for (uint256 i = 0; i < to.length; i++) {
            _withdrawNative(payable(to[i]), amount);
        }
        emit Distribute(_msgSender());
    }

    function _withdrawNative(address payable to, uint240 amount) private {
        (bool success,) = to.call{value: amount}("");
        if (!success) {
            revert RecipientRevert();
        }
    }

    /// @notice Distributes received ERC20 tokens to addresses according to configuration.
    /// @dev Atomic execution. Contract will revert all distribution if any withdrawal fails.
    /// @dev Permit (https://eips.ethereum.org/EIPS/eip-2612) is optional. ERC20(token).allow can be
    /// used. In that case any values for permit can be passed.
    /// @param config - The list of struct defines how many ether (amount) and to whom (to) should
    /// be distributed
    /// @param token - ERC20 token address that should be distributed
    /// @param permitAmount - The number of tokens to approve with a permit. Should be more or equal
    /// to the total distributed tokens.
    /// @param deadline - Permit deadline, block.timestamp (seconds)
    /// @param v - v of the secp256k1 signarure
    /// @param r - r of the secp256k1 signarure
    /// @param s - s of the secp256k1 signarure
    function distributeERC20(
        DistributionConfig[] calldata config,
        address token,
        uint240 permitAmount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        _safePermit(token, permitAmount, deadline, v, r, s);

        for (uint256 i = 0; i < config.length; i++) {
            _withdrawERC20(config[i].to, IERC20(token), config[i].amount);
        }
        emit Distribute(_msgSender());
    }

    /// @notice Distributes received ERC20 tokens to addresses
    /// @dev Atomic execution. Contract will revert all distribution if any withdrawal fails.
    /// @dev Permit (https://eips.ethereum.org/EIPS/eip-2612) is optional. ERC20(token).allow can be
    /// used. In that case any values for permit can be passed.
    /// @param amount - How many ether should be distributed to each address
    /// @param to - The recipient's address list
    /// @param token - ERC20 token address that should be distributed
    /// @param permitAmount - The number of tokens to approve with a permit. Should be more or equal
    /// to the total distributed tokens.
    /// @param deadline - Permit deadline, block.timestamp (seconds)
    /// @param v - v of the secp256k1 signarure
    /// @param r - r of the secp256k1 signarure
    /// @param s - s of the secp256k1 signarure
    function distributeERC20Fixed(
        uint240 amount,
        address[] calldata to,
        address token,
        uint240 permitAmount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        _safePermit(token, permitAmount, deadline, v, r, s);

        for (uint256 i = 0; i < to.length; i++) {
            _withdrawERC20(to[i], IERC20(token), amount);
        }
        emit Distribute(_msgSender());
    }

    function _withdrawERC20(address to, IERC20 erc20token, uint240 amount) private {
        erc20token.safeTransfer(to, amount);
    }

    function _safePermit(
        address token,
        uint240 permitAmount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) private {
        // Skip ddos transactions
        // We are not needed in either catching the error or implementing
        // a success flow. In case of error, we let safeTransferFrom revert
        try IERC20Permit(token).permit(_msgSender(), address(this), permitAmount, deadline, v, r, s)
        {} catch {}
    }
}
