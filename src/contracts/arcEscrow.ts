/**
 * ArcEscrow contract configuration
 * Deployed on Arc Testnet: 0xd7e83e4b6465b46955bc90cbbb52acd499f5c3e5
 */
import type { Abi } from 'viem'
import artifact from '../../contracts/out/ArcEscrow.sol/ArcEscrow.json'

export const ARC_ESCROW_ADDRESS = '0xd7e83e4b6465b46955bc90cbbb52acd499f5c3e5' as const

export const ARC_ESCROW_ABI = artifact.abi as Abi

export const ARC_ESCROW_CONTRACT = {
  address: ARC_ESCROW_ADDRESS,
  abi: ARC_ESCROW_ABI,
} as const

export enum EscrowState {
  Created = 0,
  Funded = 1,
  InProgress = 2,
  Completed = 3,
  Released = 4,
  Refunded = 5,
  Cancelled = 6,
}

export const ESCROW_STATE_LABELS: Record<EscrowState, string> = {
  [EscrowState.Created]: 'Created',
  [EscrowState.Funded]: 'Funded',
  [EscrowState.InProgress]: 'In Progress',
  [EscrowState.Completed]: 'Completed',
  [EscrowState.Released]: 'Released',
  [EscrowState.Refunded]: 'Refunded',
  [EscrowState.Cancelled]: 'Cancelled',
}

export type EscrowData = {
  escrowId: bigint
  buyer: string
  seller: string
  amount: bigint
  description: string
  state: EscrowState
  createdAt: bigint
  updatedAt: bigint
  completedAt: bigint
  fundedAt: bigint
}
