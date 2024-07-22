// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.16;

// solhint-disable no-global-import
// solhint-disable no-console

import "@std/Test.sol";

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Miller} from "src/Miller.sol";

import {MockERC20} from "./mocks/MockERC20.sol";
import {SigUtils} from "./utils/SigUtils.sol";

contract MillerTest is Test {
    Miller private miller;

    address private Alice;
    uint256 private AlicePk;
    MockERC20 private mockERC20 = new MockERC20();
    SigUtils internal sigUtils = new SigUtils(mockERC20.DOMAIN_SEPARATOR());

    function setUp() public {
        (Alice, AlicePk) = makeAddrAndKey("alice");
        miller = new Miller();
        vm.deal(Alice, 10 ether);
    }

    function _simplePermit(address account, uint256 amount)
        internal
        view
        returns (uint8, bytes32, bytes32)
    {
        SigUtils.Permit memory permit = SigUtils.Permit({
            owner: account,
            spender: address(miller),
            value: amount,
            nonce: 0,
            deadline: 1 days
        });

        bytes32 digest = sigUtils.getTypedDataHash(permit);
        return vm.sign(AlicePk, digest);
    }

    function _generateAccounts(uint8 amount) private returns (address[] memory) {
        address[] memory addressList = new address[](amount);
        for (uint256 i = 0; i < addressList.length; i++) {
            addressList[i] = makeAddr(Strings.toString(i * 20));
        }
        return addressList;
    }

    function _generateConfig(uint8 amount)
        private
        returns (Miller.DistributionConfig[] memory, uint240)
    {
        Miller.DistributionConfig[] memory config = new Miller.DistributionConfig[](amount);
        uint240 totalToDistribute;
        for (uint256 i = 0; i < config.length; i++) {
            uint240 amountToDistribute = uint240(i) * 20;
            totalToDistribute += amountToDistribute;
            config[i] = Miller.DistributionConfig({
                to: makeAddr(Strings.toString(i * 20)),
                amount: amountToDistribute
            });
        }
        return (config, totalToDistribute);
    }

    function testFuzz_distributeFixed(uint8 addressesAmount, uint32 amountToDistribute) public {
        vm.assume(addressesAmount > 0);
        uint240 totalDistribute = uint240(amountToDistribute) * uint240(addressesAmount);
        address[] memory addressList = _generateAccounts(addressesAmount);
        vm.prank(Alice);
        miller.distributeFixed{value: totalDistribute}(uint240(amountToDistribute), addressList);
        assertEq(Alice.balance, 10 ether - uint256(totalDistribute));
        for (uint256 i = 0; i < addressList.length; i++) {
            assertEq(addressList[i].balance, amountToDistribute);
        }
    }

    function testFuzz_distribute(uint8 addressesAmount) public {
        vm.assume(addressesAmount > 0);
        (Miller.DistributionConfig[] memory config, uint240 totalDistribute) =
            _generateConfig(addressesAmount);
        vm.prank(Alice);
        miller.distribute{value: totalDistribute}(config);
        assertEq(Alice.balance, 10 ether - uint256(totalDistribute));
        for (uint256 i = 0; i < config.length; i++) {
            assertEq(config[i].to.balance, config[i].amount);
        }
    }

    function testFuzz_distributeERC20Fixed(uint8 addressesAmount, uint32 amountToDistribute)
        public
    {
        vm.assume(addressesAmount > 0);
        uint240 totalDistribute = uint240(amountToDistribute) * uint240(addressesAmount);
        mockERC20.transfer(Alice, totalDistribute);
        address[] memory addressList = _generateAccounts(addressesAmount);
        (uint8 v, bytes32 r, bytes32 s) = _simplePermit(Alice, totalDistribute);
        vm.prank(Alice);
        miller.distributeERC20Fixed(
            uint240(amountToDistribute),
            addressList,
            address(mockERC20),
            totalDistribute,
            1 days,
            v,
            r,
            s
        );
        assertEq(mockERC20.balanceOf(Alice), 0);
        for (uint256 i = 0; i < addressList.length; i++) {
            assertEq(mockERC20.balanceOf(addressList[i]), amountToDistribute);
        }
    }

    function testFuzz_distributeERC20(uint8 addressesAmount) public {
        vm.assume(addressesAmount > 0);
        (Miller.DistributionConfig[] memory config, uint240 totalDistribute) =
            _generateConfig(addressesAmount);
        mockERC20.transfer(Alice, totalDistribute);
        address[] memory addressList = _generateAccounts(addressesAmount);
        (uint8 v, bytes32 r, bytes32 s) = _simplePermit(Alice, totalDistribute);
        vm.prank(Alice);
        miller.distributeERC20(config, address(mockERC20), totalDistribute, 1 days, v, r, s);
        assertEq(mockERC20.balanceOf(Alice), 0);
        for (uint256 i = 0; i < addressList.length; i++) {
            assertEq(mockERC20.balanceOf(config[i].to), config[i].amount);
        }
    }
}
