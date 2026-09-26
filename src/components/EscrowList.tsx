import { useEffect, useCallback } from 'react'
import { useAccount, useReadContract, useReadContracts } from 'wagmi'
import { arcTestnet } from 'viem/chains'
import { RefreshCw, Inbox } from 'lucide-react'

import { ARC_ESCROW_CONTRACT, EscrowData } from '../contracts/arcEscrow'
import { EscrowCard } from './EscrowCard'

const CHAIN_ID = arcTestnet.id

interface EscrowListProps {
  refreshTrigger: number
}

export function EscrowList({ refreshTrigger }: EscrowListProps) {
  const { address } = useAccount()

  // Fetch all escrow IDs for the user
  const {
    data: ids,
    isLoading: idsLoading,
    refetch: refetchIds,
  } = useReadContract({
    ...ARC_ESCROW_CONTRACT,
    functionName: 'getUserEscrows',
    args: address ? [address] : undefined,
    chainId: CHAIN_ID,
    query: { enabled: !!address },
  })

  // Deduplicate (user can be both buyer and seller)
  const uniqueIds = ids
    ? [...new Set((ids as bigint[]).map(id => id.toString()))].map(s => BigInt(s))
    : []

  // Fetch each escrow's data
  const contracts = uniqueIds.map(id => ({
    ...ARC_ESCROW_CONTRACT,
    functionName: 'getEscrow' as const,
    args: [id] as const,
    chainId: CHAIN_ID,
  }))

  const {
    data: escrowResults,
    isLoading: escrowsLoading,
    refetch: refetchEscrows,
  } = useReadContracts({
    contracts,
    query: { enabled: uniqueIds.length > 0 },
  })

  const escrows: EscrowData[] = (escrowResults ?? [])
    .filter(r => r.status === 'success' && r.result)
    .map(r => r.result as EscrowData)
    // Sort newest first (highest ID first)
    .sort((a, b) => (b.escrowId > a.escrowId ? 1 : -1))

  const handleRefresh = useCallback(() => {
    void refetchIds()
    void refetchEscrows()
  }, [refetchIds, refetchEscrows])

  // Re-fetch when trigger changes
  useEffect(() => {
    if (refreshTrigger > 0) handleRefresh()
  }, [refreshTrigger, handleRefresh])

  const loading = idsLoading || escrowsLoading

  if (!address) return null

  return (
    <section>
      <div className="mb-4 flex items-center justify-between">
        <h2 className="display text-base font-bold" style={{ color: 'var(--ink)' }}>
          Your Escrows
        </h2>
        <button
          onClick={handleRefresh}
          className="flex items-center gap-1.5 rounded-xl px-3 py-1.5 text-xs font-semibold transition-all"
          style={{ color: 'var(--muted)', background: 'var(--surface-muted)' }}
          disabled={loading}
        >
          <RefreshCw className={`size-3.5 ${loading ? 'animate-spin' : ''}`} />
          Refresh
        </button>
      </div>

      {loading && uniqueIds.length === 0 && (
        <div className="space-y-3">
          {[0, 1, 2].map(i => (
            <SkeletonCard key={i} />
          ))}
        </div>
      )}

      {!loading && escrows.length === 0 && (
        <div
          className="flex flex-col items-center justify-center gap-3 rounded-3xl py-12"
          style={{ background: 'var(--surface)', border: '1px solid var(--border)' }}
        >
          <div
            className="flex size-12 items-center justify-center rounded-2xl"
            style={{ background: 'var(--surface-muted)' }}
          >
            <Inbox className="size-6" style={{ color: 'var(--subtle)' }} />
          </div>
          <p className="text-sm font-medium" style={{ color: 'var(--muted)' }}>
            No escrows yet
          </p>
          <p className="text-xs text-center max-w-xs" style={{ color: 'var(--subtle)' }}>
            Create your first escrow using the button above, or wait for a buyer to add you as a seller.
          </p>
        </div>
      )}

      {escrows.length > 0 && (
        <div className="space-y-3">
          {escrows.map(escrow => (
            <EscrowCard
              key={escrow.escrowId.toString()}
              escrow={escrow}
              onRefresh={handleRefresh}
            />
          ))}
        </div>
      )}
    </section>
  )
}

function SkeletonCard() {
  return (
    <div
      className="rounded-3xl p-5 space-y-3 animate-pulse"
      style={{ background: 'var(--surface)', border: '1px solid var(--border)' }}
    >
      <div className="flex items-center gap-3">
        <div className="size-9 rounded-xl" style={{ background: 'var(--surface-muted)' }} />
        <div className="flex-1 space-y-1.5">
          <div className="h-3 w-2/3 rounded-lg" style={{ background: 'var(--surface-muted)' }} />
          <div className="h-2.5 w-1/3 rounded-lg" style={{ background: 'var(--surface-muted)' }} />
        </div>
        <div className="h-5 w-20 rounded-full" style={{ background: 'var(--surface-muted)' }} />
      </div>
      <div className="h-14 rounded-2xl" style={{ background: 'var(--surface-muted)' }} />
    </div>
  )
}
