# VestingProtocol

A minimal, single-beneficiary linear token vesting contract built with Solidity and Foundry.

## Overview

`VestingProtocol` locks a fixed amount of ERC20 tokens for a single beneficiary and releases them linearly over a fixed duration, starting from the moment the contract is deployed. There is no admin, no owner, and no way to modify the schedule after deployment — all core parameters (`beneficiary`, `token`, `start`, `duration`) are set once in the constructor and stored as `immutable`.

This design intentionally trades flexibility for simplicity and auditability: a single, self-contained vesting instance per beneficiary, rather than a shared registry managing many schedules.

## Features

- **Linear vesting** — tokens unlock continuously and proportionally to elapsed time, not in discrete monthly chunks
- **Immutable parameters** — beneficiary, token, start time, and duration cannot be changed after deployment
- **No admin/owner** — nobody, including the deployer, can revoke, pause, or redirect the vesting once it's live
- **Partial claims** — the beneficiary can call `release()` at any time to withdraw whatever has vested so far; unclaimed vested tokens simply accumulate for a later claim

## Contract

### Constructor

```solidity
constructor(address _beneficiary, address _token, uint256 _duration, uint256 _totalAmount)
```

Validates that none of the addresses are zero and that duration/amount are non-zero. Sets `start` to `block.timestamp` at deployment time — vesting begins immediately.

> **Note:** After deployment, the contract must be funded manually by transferring `_totalAmount` of the token to the contract's address. The constructor only records the amount; it does not pull tokens in.

### Functions

| Function | Description |
|---|---|
| `release()` | Callable only by `beneficiary`. Transfers all currently releasable tokens to the beneficiary and updates the `released` counter. |
| `vestedAmount()` | View function. Returns the total amount vested so far, based on linear interpolation between `start` and `start + duration`. |
| `releasableAmount()` | View function. Returns `vestedAmount() - released` — the amount currently claimable. |

### Vesting formula

```
if now < start:              vested = 0
if now >= start + duration:  vested = totalAmount
otherwise:                   vested = totalAmount * (now - start) / duration
```

## Getting Started

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- [OpenZeppelin Contracts](https://github.com/OpenZeppelin/openzeppelin-contracts)

```bash
forge install OpenZeppelin/openzeppelin-contracts
```

### Build

```bash
forge build
```

### Test

```bash
forge test -vv
```

Tests cover constructor validation, linear vesting math at the midpoint and end of the duration, correct token transfer on `release()`, and access control (only the beneficiary can call `release()`).

### Deploy

Update the placeholder `beneficiary` and `token` addresses in `script/DeployVestingProtocol.s.sol`, then run:

```bash
forge script script/DeployVestingProtocol.s.sol --broadcast --rpc-url <YOUR_RPC_URL> --private-key <YOUR_PRIVATE_KEY>
```

After deployment, fund the contract by sending `totalAmount` of the vesting token to the deployed contract address.

## Design Decisions

- **Linear over cliff-based vesting** — chosen for simplicity in v1 and to avoid discrete "unlock dates" that create claim-timing pressure. A cliff period may be added in a future version without changing the core release logic.
- **Single beneficiary per contract** — rather than a multi-beneficiary registry, each vesting agreement gets its own contract instance. This keeps the trust surface minimal and avoids the storage/gas overhead of a schedule mapping.
- **Checks-Effects-Interactions pattern** — `release()` updates the `released` state before making the external token transfer, preventing reentrancy from affecting internal accounting.
- **No owner/admin** — removes the risk of centralized interference with an already-agreed vesting schedule, at the cost of no revocation mechanism.

## License

MIT