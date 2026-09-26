# Arc Escrow

> Built with Arc Studio — money-powered apps in minutes

This is the **project memory** for the Arc Escrow application.

---

## What This App Does

A production-quality decentralized escrow application built on Arc Testnet. Allows a buyer and seller to create, fund, and complete non-custodial USDC escrow agreements through a Solidity smart contract — no middleman, no trust required.

Core flow: Create → Fund → Complete → Release  
Alternate flows: Cancel (pre-funding), Refund (24h lock after funding), Emergency Refund (30-day timeout after completion)

## Tech Stack

- Frontend: React 18, Vite, TypeScript, Tailwind CSS
- Web3: wagmi v2, viem v2, ConnectKit
- Contracts: Solidity 0.8.20 + Foundry. Sources in `contracts/`, unit tests in `contracts/test/*.t.sol`.
- Wallet: injected (MetaMask, etc.)
- Chain: Arc Testnet (Chain ID: 5042002)
- Token: USDC (6 decimals) (Address: 0x3600000000000000000000000000000000000000, Chain: Arc Testnet)
- Toasts: Sonner

## Deployed Contract

| | |
|---|---|
| **Contract** | ArcEscrow |
| **Address** | `0xd7e83e4b6465b46955bc90cbbb52acd499f5c3e5` |
| **Network** | Arc Testnet (Chain ID: 5042002) |
| **Explorer** | https://explorer.testnet.arc.io/address/0xd7e83e4b6465b46955bc90cbbb52acd499f5c3e5 |
| **USDC token** | `0x3600000000000000000000000000000000000000` |

## Key Files

- `src/App.tsx` — Main application layout
- `src/components/` — UI components (Header, EscrowCard, EscrowList, CreateEscrowSheet, etc.)
- `src/contracts/arcEscrow.ts` — Contract ABI, address, types
- `src/utils/escrow.ts` — Formatting helpers, error parsing
- `contracts/ArcEscrow.sol` — Solidity contract source
- `contracts/test/ArcEscrow.t.sol` — Foundry test suite (70 tests, all passing)

## Contract Functions

| Function | Access | Description |
|---|---|---|
| `createEscrow(seller, amount, description)` | anyone | Create a new escrow |
| `fundEscrow(escrowId)` | buyer only | Deposit USDC into contract |
| `markCompleted(escrowId)` | seller only | Mark work as completed |
| `releaseFunds(escrowId)` | buyer only | Release USDC to seller |
| `cancelEscrow(escrowId)` | buyer only | Cancel before funding |
| `refundEscrow(escrowId)` | buyer only | Refund after 24h lock period |
| `emergencyRefund(escrowId)` | buyer only | Refund after 30-day timeout from completion |
| `getEscrow(escrowId)` | view | Get escrow details |
| `getUserEscrows(address)` | view | Get all escrow IDs for a user |

## Security Properties

- ReentrancyGuard on all fund-moving functions
- Checks-Effects-Interactions pattern strictly enforced
- Custom errors (no require strings)
- 24-hour refund lock period protects sellers from front-running
- 30-day emergency refund timeout protects buyers from blocklisted sellers
- No tx.origin usage
- No hardcoded secrets or private keys

## To Run

```bash
bun install
bun run dev
```

## To Test

```bash
bun run contracts:test
# or
forge test
```

## To Build

```bash
bun run build
```
