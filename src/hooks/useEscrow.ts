import { useReadContract, useReadContracts } from 'wagmi'
import { ARC_ESCROW_CONTRACT, EscrowData } from '../contracts/arcEscrow'
import { arcTestnet } from 'viem/chains'

const CHAIN_ID = arcTestnet.id

export function useEscrow(escrowId: bigint | undefined) {
  return useReadContract({
    ...ARC_ESCROW_CONTRACT,
    functionName: 'getEscrow',
    args: escrowId !== undefined ? [escrowId] : undefined,
    chainId: CHAIN_ID,
    query: { enabled: escrowId !== undefined },
  })
}

export function useUserEscrows(address: string | undefined) {
  return useReadContract({
    ...ARC_ESCROW_CONTRACT,
    functionName: 'getUserEscrows',
    args: address ? [address as `0x${string}`] : undefined,
    chainId: CHAIN_ID,
    query: { enabled: !!address },
  })
}

export function useMultipleEscrows(ids: bigint[]) {
  const contracts = ids.map((id) => ({
    ...ARC_ESCROW_CONTRACT,
    functionName: 'getEscrow' as const,
    args: [id] as const,
    chainId: CHAIN_ID,
  }))

  return useReadContracts({
    contracts,
    query: { enabled: ids.length > 0 },
  })
}

export function parseEscrowResult(raw: unknown): EscrowData | null {
  if (!raw || !Array.isArray(raw) && typeof raw !== 'object') return null
  const r = raw as EscrowData
  if (!r.escrowId && r.escrowId !== 0n) return null
  return r
}
