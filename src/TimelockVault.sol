// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title Per-user ETH timelock
contract TimelockVault {
    struct Lock {
        uint128 amount;
        uint64 unlockAt;
    }

    mapping(address => Lock) public locks;

    event Deposited(address indexed user, uint256 amount, uint256 unlockAt);
    event Extended(address indexed user, uint256 unlockAt);
    event Withdrawn(address indexed user, uint256 amount);

    error ZeroDeposit();
    error UnlockInPast();
    error CannotShorten(uint256 current);
    error StillLocked(uint256 unlockAt);
    error NothingToWithdraw();
    error TransferFailed();

    function deposit(uint64 unlockAt) external payable {
        if (msg.value == 0) revert ZeroDeposit();
        if (unlockAt <= block.timestamp) revert UnlockInPast();
        Lock storage l = locks[msg.sender];
        if (unlockAt < l.unlockAt) revert CannotShorten(l.unlockAt);
        l.amount += uint128(msg.value);
        l.unlockAt = unlockAt;
        emit Deposited(msg.sender, msg.value, unlockAt);
    }

    function extend(uint64 unlockAt) external {
        Lock storage l = locks[msg.sender];
        if (l.amount == 0) revert NothingToWithdraw();
        if (unlockAt <= l.unlockAt) revert CannotShorten(l.unlockAt);
        l.unlockAt = unlockAt;
        emit Extended(msg.sender, unlockAt);
    }

    function withdraw() external {
        Lock memory l = locks[msg.sender];
        if (l.amount == 0) revert NothingToWithdraw();
        if (block.timestamp < l.unlockAt) revert StillLocked(l.unlockAt);
        delete locks[msg.sender];
        (bool ok,) = msg.sender.call{value: l.amount}("");
        if (!ok) revert TransferFailed();
        emit Withdrawn(msg.sender, l.amount);
    }
}
