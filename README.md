# eth-timelock-vault

An ETH vault that won't let you withdraw before a date you pick. Each address has its own lock.

| function | what it does |
|---|---|
| `deposit(unlockAt)` | adds ETH. `unlockAt` must be in the future and not earlier than your current unlock time |
| `extend(unlockAt)` | moves the unlock time later |
| `withdraw()` | sends everything back once `block.timestamp >= unlockAt` |

There is no admin and no early withdrawal, and a lock can never be shortened.

Implementation notes:

- the lock fits in one storage slot (`uint128 amount`, `uint64 unlockAt`)
- `withdraw` clears the state before sending ETH (checks, effects, interactions)
- the errors carry the relevant values, for example `StillLocked(unlockAt)`

```bash
forge build
forge test -vv
```
