# Arc Escrow

A non-custodial onchain escrow application built on Arc Testnet.

Arc Escrow enables buyers and sellers to create, fund, complete, and release USDC payments through a smart contract without relying on a centralized intermediary.

## Live Demo

https://soft-jalebi-0de10e.netlify.app/

## Overview

Arc Escrow provides a simple onchain workflow for transactions between two parties.

A buyer creates an escrow with a seller, deposits USDC into the smart contract, and releases the funds after the seller completes the work.

The smart contract controls the escrow state and ensures that funds can only move according to the defined rules.

## Escrow Flow

``text
Buyer
  │
  ▼
Create Escrow
  │
  ▼
Fund Escrow
  │
  ▼
Seller Completes Work
  │
  ▼
Buyer Releases Funds
  │
  ▼
Seller Receives USDC
Features
🔐 Non-custodial escrow
💵 USDC-based payments
👛 Wallet-based authentication
🔄 Onchain escrow state management
🤝 Buyer and seller roles
✅ Seller completion confirmation
💸 Buyer-controlled fund release
↩️ Refund and cancellation flows
🛡️ Reentrancy protection
🔒 Access-controlled contract actions
📊 Escrow status tracking
🔎 ArcScan transaction links
🌐 Arc Testnet deployment
Escrow States

The escrow follows a controlled state machine:
Created
   │
   ▼
Funded
   │
   ▼
Completed
   │
   ▼
Released
Additional refund and cancellation paths are available when their conditions are satisfied.

How It Works
1. Create an Escrow

The buyer enters:

Seller wallet address
USDC amount
Payment description

The escrow is created onchain.

2. Fund the Escrow

The buyer approves USDC and funds the escrow contract.

The funds remain controlled by the smart contract.

3. Seller Completes

After completing the agreed work, the seller marks the escrow as completed.

4. Release Funds

The buyer reviews the completed escrow and releases the funds.

The USDC is transferred to the seller.

5. Refund / Emergency Protection

The contract also includes cancellation, refund, and emergency refund mechanisms for supported scenarios.

Smart Contract

Contract:
0xd7e83e4b6465b46955bc90cbbb52acd499f5c3e5

Network: Arc Testnet

Chain ID: 5042002

Explorer:
https://explorer.testnet.arc.io/address/0xd7e83e4b6465b46955bc90cbbb52acd499f5c3e5

Smart Contract Functions

Core functions include:

createEscrow()
fundEscrow()
markCompleted()
releaseFunds()
cancelEscrow()
refundEscrow()
emergencyRefund()
getEscrow()
getUserEscrows()
Security

The contract was designed with security-focused protections including:

Role-based access control
Escrow state validation
Reentrancy protection
Checks-effects-interactions pattern
Double-release prevention
Double-refund prevention
Invalid participant protection
Zero-value escrow prevention
Custom Solidity errors
Indexed events
Time-based refund protection
Emergency refund mechanism

No private keys, seed phrases, or wallet credentials are stored in the repository.

Testing

The project includes a comprehensive Foundry test suite.

70 / 70 tests passing

Tests cover:

Escrow creation
Funding
Completion
Release
Cancellation
Refunds
Emergency refunds
Access control
Invalid state transitions
Reentrancy protection
Events
Fuzz testing
Edge cases
Tech Stack
Solidity
Foundry
React
TypeScript
Vite
Tailwind CSS
Bun
Arc Testnet
Project Structure
arc-escroww/
├── contracts/
│   └── ArcEscrow.sol
├── scripts/
├── src/
│   ├── components/
│   ├── hooks/
│   └── ...
├── foundry.toml
├── package.json
├── vite.config.ts
└── README.md
Getting Started
Install dependencies
bun install
Start development server
bun run dev

The application is designed to run against Arc Testnet.

Testnet Notice

This project is deployed on Arc Testnet for learning and experimentation.

Testnet assets have no monetary value.

Never commit .env files, private keys, seed phrases, or other secrets to GitHub.

Built With Arc Studio

This project was built and tested using Arc Studio to explore smart contract development, onchain application design, and financial workflows on Arc Testnet.

Project Status

Testnet project — actively built for experimentation, learning, and Web3 development.

Author

Built by vijay0664kumar

License

MIT
