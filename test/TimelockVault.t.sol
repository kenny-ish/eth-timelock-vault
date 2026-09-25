// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {TimelockVault} from "../src/TimelockVault.sol";
import {vm} from "./Vm.sol";

contract TimelockVaultTest {
    TimelockVault vault;
    uint64 constant T0 = 1_700_000_000;

    receive() external payable {}

    function setUp() public {
        vm.warp(T0);
        vault = new TimelockVault();
    }

    function test_DepositAndWithdrawAfterUnlock() public {
        vault.deposit{value: 1 ether}(T0 + 30 days);
        vm.warp(T0 + 30 days);
        uint256 before = address(this).balance;
        vault.withdraw();
        require(address(this).balance == before + 1 ether, "not paid back");
        (uint128 amount,) = vault.locks(address(this));
        require(amount == 0, "lock not cleared");
    }

    function test_RevertWhen_WithdrawTooEarly() public {
        vault.deposit{value: 1 ether}(T0 + 1 days);
        vm.expectRevert(abi.encodeWithSelector(TimelockVault.StillLocked.selector, uint256(T0 + 1 days)));
        vault.withdraw();
    }

    function test_TopUpCannotShorten() public {
        vault.deposit{value: 1 ether}(T0 + 10 days);
        vm.expectRevert(abi.encodeWithSelector(TimelockVault.CannotShorten.selector, uint256(T0 + 10 days)));
        vault.deposit{value: 1 ether}(T0 + 5 days);
        vault.deposit{value: 1 ether}(T0 + 20 days);
        (uint128 amount, uint64 unlockAt) = vault.locks(address(this));
        require(amount == 2 ether && unlockAt == T0 + 20 days, "top up");
    }

    function test_Extend() public {
        vault.deposit{value: 1 ether}(T0 + 1 days);
        vault.extend(T0 + 2 days);
        vm.warp(T0 + 1 days);
        vm.expectRevert(abi.encodeWithSelector(TimelockVault.StillLocked.selector, uint256(T0 + 2 days)));
        vault.withdraw();
    }

    function test_RevertWhen_UnlockInPast() public {
        vm.expectRevert(TimelockVault.UnlockInPast.selector);
        vault.deposit{value: 1 ether}(T0);
    }
}
