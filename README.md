# Arc Escrow V2

A non-custodial onchain escrow application built on **Arc Testnet**.

Arc Escrow V2 enables users to create, fund, complete, and settle escrow agreements directly through a smart contract without relying on a centralized intermediary.

## 🌐 Live Demo

https://soft-jalebi-0de10e.netlify.app/

---

## ✨ Overview

Arc Escrow V2 provides an onchain escrow workflow for peer-to-peer transactions.

Users can:

- Create escrow agreements
- Select supported tokens
- Define buyer and seller
- Lock funds onchain
- Track escrow status
- Complete transactions
- Release funds
- Handle eligible refunds
- Search and filter escrows
- View escrow activity history
- Share escrow links
- Receive transaction notifications

All escrow state transitions are enforced by the smart contract.

---

## 🚀 Features

### 🔐 Non-Custodial Escrow

Funds are controlled by the smart contract rather than a centralized platform.

### 💰 Multi-Token Support

V2 supports multiple ERC-20 tokens through a configurable supported-token system.

### 📊 Escrow Dashboard

Track escrow activity through dashboard statistics including:

- Total escrows
- Active escrows
- Completed escrows
- Released escrows
- Refunded escrows
- Volume tracking
- Token-specific statistics

### 🔎 Search & Filters

Search escrows by:

- Escrow ID
- Wallet address
- Description

Filter escrows by:

- All
- Active
- Funded
- Completed
- Released
- Refunded
- Disputed

### 📜 Activity History

Each escrow can display its onchain activity:

- Created
- Funded
- Completed
- Released
- Refunded
- Cancelled

Transaction timestamps and transaction links are displayed where available.

### 🔗 Shareable Escrow Links

Each escrow can be opened using a dedicated URL:

``text
/escrow/<escrow-id>

Users can also copy the escrow ID or share the escrow directly.

🔔 Notifications

The application provides transaction and escrow-status notifications based on onchain events.

💸 Protocol Fee

Arc Escrow V2 currently uses a 0.5% protocol fee.

The fee is configured at deployment and handled according to the smart contract rules.

🔄 Escrow Flow
Create Escrow
      │
      ▼
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

Eligible cancellation and refund paths are handled according to the smart contract's state rules.

🧠 How It Works
Connect your wallet.
Select a supported token.
Enter the buyer and seller addresses.
Enter the escrow amount.
Add a description.
Create the escrow.
The required party funds the escrow.
The transaction is completed.
The authorized party releases the funds.
The smart contract settles the escrow according to its state.
📜 Smart Contract
Arc Escrow V2

Contract Address

0xd81fef645eb8abd641ea2ba6d7b33ad09b704be0

Network

Arc Testnet

Chain ID

5042002

Deployment Transaction

0x89f4cd900031062ffd2429a1c5c94d06bc39551d923befb29ef823d70d783630
💵 Supported USDC

The current deployment supports Arc Testnet USDC:

0x3600000000000000000000000000000000000000

Additional ERC-20 tokens can be configured through the contract's supported-token mechanism.

🛡️ Security Model

Arc Escrow V2 is designed around a non-custodial smart-contract architecture.

Key protections include:

Role-based escrow state transitions
Controlled fund release
Eligibility-based refunds
Supported-token validation
Fee configuration
Escrow state validation
Onchain transaction verification

The application does not require users to deposit funds into a centralized wallet.

🧪 Testing

The project was developed and tested using Arc Studio and Foundry.

The test suite covers areas including:

Escrow creation
Escrow funding
Transaction completion
Fund release
Refunds
Cancellation
Token handling
Fee handling
Access control
Edge cases
🧰 Tech Stack
Solidity
React
TypeScript
Vite
Tailwind CSS
Bun
Foundry
Arc Testnet
ERC-20
📁 Project Structure
arc-escroww/
├── contracts/
├── scripts/
├── src/
│   ├── contracts/
│   ├── components/
│   ├── pages/
│   └── ...
├── foundry.toml
├── package.json
├── vite.config.ts
└── README.md
🛠️ Getting Started
Clone
git clone https://github.com/vijay0664kumar/arc-escroww.git
cd arc-escroww
Install Dependencies
bun install
Run Development Server
bun run dev

The application will start using the Vite development server.


🌐 Network Configuration

Network: Arc Testnet

Chain ID: 5042002


Make sure your wallet is connected to the correct network before interacting with the application.


⚠️ Testnet Notice


This project is deployed on Arc Testnet for development, experimentation, and learning.


Testnet assets have no monetary value.


Never use real funds or expose private keys, seed phrases, API keys, or other credentials.


🏗️ Built With Arc Studio


Arc Escrow V2 was built and tested using Arc Studio to explore smart contract development, onchain application architecture, and escrow workflows on Arc Testnet.


📌 Project Status

Status: Testnet

Arc Escrow V2 is an experimental onchain escrow application built for testing and learning.
The project may evolve as additional escrow features and supported assets are explored.


👤 Author

Built by vijay0664kumar


GitHub: https://github.com/vijay0664kumar


📄 License

MIT License
