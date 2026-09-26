# Arc Escrow

A non-custodial onchain escrow application built on Arc Testnet.

Arc Escrow allows a buyer and seller to create a deal, lock USDC in a smart contract, confirm completion, and release payment without relying on a centralized intermediary.

## Live Demo

https://soft-jalebi-0de10e.netlify.app/

## Overview

Arc Escrow provides a simple onchain workflow for digital agreements and payments.

The buyer creates an escrow with:

- Seller wallet address
- USDC payment amount
- Deal description

The payment is then locked in the smart contract until the required conditions are met.

### Escrow Flow
``text
Create Escrow
      ↓
Approve USDC
      ↓
Fund Escrow
      ↓
Seller Completes Work
      ↓
Buyer Releases Payment
      ↓
Seller Receives USDC

Features
Connect wallet
Create onchain escrow agreements
Specify seller wallet address
Set USDC payment amount
Add deal descriptions
Approve and fund escrow
Lock USDC inside the smart contract
Seller-controlled completion
Buyer-controlled payment release
Refund and cancellation flows
Emergency refund protection
Escrow status tracking
Buyer and seller wallet identification
Transaction status feedback
ArcScan transaction links
Arc Testnet support
Non-custodial architecture
Escrow States
The smart contract uses explicit escrow states to control the lifecycle of each agreement.
Created
   ↓
Funded
   ↓
Completed
   ↓
Released
Additional refund and cancellation paths are available according to the escrow conditions.

How It Works
1. Create

The buyer creates an escrow by providing the seller's wallet address, payment amount, and deal description.

2. Approve

The buyer approves the escrow contract to spend the required USDC amount.

3. Fund

The buyer deposits USDC into the escrow smart contract.

The funds remain locked in the contract.

4. Complete

The seller marks the work or agreement as completed.

5. Release

The buyer releases the escrow payment.

The locked USDC is transferred to the seller.

Smart Contract

Contract: ArcEscrow

Address:

0xd7e83e4b6465b46955bc90cbbb52acd499f5c3e5

Network: Arc Testnet

Chain ID: 5042002

Explorer:

https://explorer.testnet.arc.io/address/0xd7e83e4b6465b46955bc90cbbb52acd499f5c3e5

Smart Contract Functions

The escrow contract includes core functions for managing the complete escrow lifecycle:

createEscrow()
fundEscrow()
markCompleted()
releaseFunds()
cancelEscrow()
refundEscrow()
emergencyRefund()
getEscrow()
getUserEscrows()

Access controls ensure that escrow actions can only be performed by the appropriate participants.

Security

The contract was designed with security-focused development practices including:

Reentrancy protection
Checks-effects-interactions pattern
Custom Solidity errors
Indexed events
Participant authorization
State transition validation
Double-release protection
Double-refund protection
Zero-value validation
Invalid seller protection
No tx.origin usage
Time-lock protections
Emergency refund mechanism
Security Review

The project went through multiple security review passes during development.

70/70 Foundry tests passing
No Critical findings
No High findings
Remaining Slither findings are low-impact timestamp warnings related to time-based escrow conditions
Testing

The smart contract includes comprehensive Foundry tests covering:

Escrow creation
Funding
Completion
Payment release
Cancellation
Refunds
Emergency refunds
Access control
Invalid state transitions
Double execution protection
Events
Reentrancy scenarios
Fuzz testing

Test result:

70/70 tests passing
Tech Stack
Solidity
React
TypeScript
Vite
Tailwind CSS
Bun
Foundry
Arc Testnet
USDC
Project Structure
arc-escrow/
├── contracts/
│   └── ArcEscrow.sol
├── scripts/
├── src/
├── public/
├── test/
├── foundry.toml
├── package.json
├── bun.lock
├── vite.config.ts
├── tailwind.config.ts
├── tsconfig.json
├── .gitignore
└── README.md
Getting Started
Install dependencies
bun install
Start the development server
bun run dev

The application will be available locally through the Vite development server.

Testnet Notice

This project is deployed on Arc Testnet for learning and experimentation.

Testnet assets have no monetary value.

Never commit .env, private keys, or seed phrases.

Built With Arc Studio

This project was built and tested using Arc Studio to explore smart contract development and onchain escrow and payment workflows on Arc Testnet.

Status

Testnet project — fully deployed and tested.

The complete Create → Fund → Complete → Release escrow flow has been successfully tested on Arc Testnet.

Author

Built by vijay0664kumar

License

MIT
