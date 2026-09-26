import { EscrowState } from '../contracts/arcEscrow'
import { formatUnits } from 'viem'

export function formatAddress(addr: string): string {
  if (!addr || addr.length < 10) return addr
  return `${addr.slice(0, 6)}...${addr.slice(-4)}`
}

export function formatUsdc(raw: bigint): string {
  return new Intl.NumberFormat('en-US', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 6,
  }).format(parseFloat(formatUnits(raw, 6)))
}

export function formatDate(ts: bigint): string {
  if (ts === 0n) return '—'
  return new Date(Number(ts) * 1000).toLocaleString(undefined, {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  })
}

export type StateColor = 'blue' | 'amber' | 'indigo' | 'green' | 'emerald' | 'gray' | 'red'

export function stateColor(state: EscrowState): StateColor {
  switch (state) {
    case EscrowState.Created:    return 'blue'
    case EscrowState.Funded:     return 'amber'
    case EscrowState.InProgress: return 'indigo'
    case EscrowState.Completed:  return 'green'
    case EscrowState.Released:   return 'emerald'
    case EscrowState.Refunded:   return 'gray'
    case EscrowState.Cancelled:  return 'red'
    default:                     return 'gray'
  }
}

export function parseOnchainError(error: unknown): string {
  const e = error as { message?: string; code?: number }
  const msg = e?.message?.toLowerCase() ?? ''

  if (msg.includes('user rejected') || e?.code === 4001) return 'Transaction cancelled.'
  if (msg.includes('notbuyer'))         return 'Only the buyer can perform this action.'
  if (msg.includes('notseller'))        return 'Only the seller can perform this action.'
  if (msg.includes('invalidstate'))     return 'This action is not allowed in the current escrow state.'
  if (msg.includes('zeroamount'))       return 'Amount must be greater than zero.'
  if (msg.includes('invalidseller'))    return 'Seller address cannot be your own address.'
  if (msg.includes('zeroaddress'))      return 'Please enter a valid wallet address.'
  if (msg.includes('escrownotfound'))   return 'Escrow not found.'
  if (msg.includes('releaseperiodnotexpired')) return 'The 30-day emergency recovery window has not elapsed yet.'
  if (msg.includes('refundlockactive')) return 'Refunds are locked for 24 hours after funding to protect the seller.'
  if (msg.includes('insufficient funds') || msg.includes('exceeds balance'))
    return 'Insufficient USDC balance. Please add funds via the Get test USDC button.'
  if (msg.includes('allowance'))        return 'Insufficient USDC allowance. Please approve the contract first.'
  if (msg.includes('reverted'))         return 'Transaction failed. Please check the escrow state and try again.'
  if (msg.includes('network') || msg.includes('timeout'))
    return 'Network error. Please check your connection and retry.'

  return 'Something went wrong. Please try again.'
}
