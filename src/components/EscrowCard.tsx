import { useState, useEffect, useRef } from 'react'
import { useAccount, useWriteContract, useWaitForTransactionReceipt, useReadContract } from 'wagmi'
import { erc20Abi } from 'viem'
import { arcTestnet } from 'viem/chains'
import { toast } from 'sonner'
import { ExternalLink, ChevronDown, ChevronUp, User, ShoppingBag } from 'lucide-react'

import { ARC_ESCROW_CONTRACT, EscrowData, EscrowState } from '../contracts/arcEscrow'
import { StateBadge } from './StateBadge'
import { TxButton } from './TxButton'
import { formatAddress, formatUsdc, formatDate, parseOnchainError } from '../utils/escrow'
import { buildTxExplorerUrl, buildAddressExplorerUrl, getUsdc } from '../onchain-facts'

const CHAIN_ID = arcTestnet.id
const USDC = getUsdc(CHAIN_ID)!

interface EscrowCardProps {
  escrow: EscrowData
  onRefresh: () => void
}

export function EscrowCard({ escrow, onRefresh }: EscrowCardProps) {
  const { address } = useAccount()
  const [expanded, setExpanded] = useState(false)

  const isBuyer  = address?.toLowerCase() === escrow.buyer.toLowerCase()
  const isSeller = address?.toLowerCase() === escrow.seller.toLowerCase()

  // ── USDC allowance check (for funding) ──────────────────────────────────
  const { data: allowance } = useReadContract({
    address: USDC.address as `0x${string}`,
    abi: erc20Abi,
    functionName: 'allowance',
    args: address ? [address, ARC_ESCROW_CONTRACT.address] : undefined,
    chainId: CHAIN_ID,
    query: { enabled: !!address && escrow.state === EscrowState.Created },
  })

  // ── Shared write + wait hooks ────────────────────────────────────────────
  const { writeContract, data: txHash, isPending, reset: resetWrite } = useWriteContract()
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash: txHash })
  const processedRef = useRef<string | undefined>(undefined)

  // Refresh once per confirmed txHash
  useEffect(() => {
    if (isSuccess && txHash && processedRef.current !== txHash) {
      processedRef.current = txHash
      onRefresh()
      resetWrite()
    }
  }, [isSuccess, txHash, onRefresh, resetWrite])

  function handleTx(fn: () => void) {
    try {
      fn()
    } catch (err) {
      toast.error(parseOnchainError(err))
    }
  }

  // ── Approve then fund ────────────────────────────────────────────────────
  const needsApproval = (allowance ?? 0n) < escrow.amount

  function handleApprove() {
    handleTx(() =>
      writeContract({
        address: USDC.address as `0x${string}`,
        abi: erc20Abi,
        functionName: 'approve',
        args: [ARC_ESCROW_CONTRACT.address, escrow.amount],
      }),
    )
  }

  function handleFund() {
    handleTx(() =>
      writeContract({ ...ARC_ESCROW_CONTRACT, functionName: 'fundEscrow', args: [escrow.escrowId] }),
    )
  }

  function handleMarkComplete() {
    handleTx(() =>
      writeContract({ ...ARC_ESCROW_CONTRACT, functionName: 'markCompleted', args: [escrow.escrowId] }),
    )
  }

  function handleRelease() {
    handleTx(() =>
      writeContract({ ...ARC_ESCROW_CONTRACT, functionName: 'releaseFunds', args: [escrow.escrowId] }),
    )
  }

  function handleCancel() {
    handleTx(() =>
      writeContract({ ...ARC_ESCROW_CONTRACT, functionName: 'cancelEscrow', args: [escrow.escrowId] }),
    )
  }

  function handleRefund() {
    handleTx(() =>
      writeContract({ ...ARC_ESCROW_CONTRACT, functionName: 'refundEscrow', args: [escrow.escrowId] }),
    )
  }

  function handleEmergencyRefund() {
    handleTx(() =>
      writeContract({ ...ARC_ESCROW_CONTRACT, functionName: 'emergencyRefund', args: [escrow.escrowId] }),
    )
  }

  const state = escrow.state

  // Derive which actions are available
  const canApprove  = isBuyer  && state === EscrowState.Created && needsApproval
  const canFund     = isBuyer  && state === EscrowState.Created && !needsApproval
  const canCancel   = isBuyer  && state === EscrowState.Created
  const canRefund   = isBuyer  && (state === EscrowState.Funded || state === EscrowState.InProgress)
  const canComplete = isSeller && state === EscrowState.Funded
  const canRelease  = isBuyer  && state === EscrowState.Completed
  const canEmergency = isBuyer && state === EscrowState.Completed

  const isTerminal = [EscrowState.Released, EscrowState.Refunded, EscrowState.Cancelled].includes(state)

  const txUrl = txHash ? buildTxExplorerUrl(CHAIN_ID, txHash) : undefined

  return (
    <article
      className="rounded-3xl overflow-hidden"
      style={{
        background: 'var(--surface)',
        border: '1px solid var(--border)',
        backdropFilter: 'blur(20px)',
      }}
    >
      {/* ── Header ──────────────────────────────────────────────────────── */}
      <div className="flex items-start justify-between gap-4 p-5">
        <div className="flex items-center gap-3 min-w-0">
          <div
            className="flex size-9 shrink-0 items-center justify-center rounded-xl text-sm font-bold display"
            style={{ background: 'var(--surface-muted)', color: 'var(--muted)' }}
          >
            #{escrow.escrowId.toString()}
          </div>
          <div className="min-w-0">
            <p className="truncate text-sm font-semibold" style={{ color: 'var(--ink)' }}>
              {escrow.description || 'No description'}
            </p>
            <p className="mt-0.5 text-xs" style={{ color: 'var(--muted)' }}>
              {isBuyer ? 'You are the buyer' : isSeller ? 'You are the seller' : 'Participant'}
            </p>
          </div>
        </div>
        <div className="flex items-center gap-2 shrink-0">
          <StateBadge state={state} />
          <button
            onClick={() => setExpanded(v => !v)}
            className="rounded-xl p-1.5 transition-colors"
            style={{ color: 'var(--muted)' }}
          >
            {expanded ? <ChevronUp className="size-4" /> : <ChevronDown className="size-4" />}
          </button>
        </div>
      </div>

      {/* ── Amount row ──────────────────────────────────────────────────── */}
      <div
        className="mx-4 mb-4 flex items-center justify-between rounded-2xl px-4 py-3"
        style={{ background: 'var(--surface-muted)' }}
      >
        <div>
          <p className="text-xs font-medium" style={{ color: 'var(--muted)' }}>Amount</p>
          <p className="display text-xl font-bold tabular-nums" style={{ color: 'var(--ink)' }}>
            {formatUsdc(escrow.amount)}
            <span className="ml-1 text-sm font-medium" style={{ color: 'var(--subtle)' }}>USDC</span>
          </p>
        </div>
        <div className="text-right">
          <p className="text-xs font-medium" style={{ color: 'var(--muted)' }}>Created</p>
          <p className="text-xs tabular-nums" style={{ color: 'var(--subtle)' }}>
            {formatDate(escrow.createdAt)}
          </p>
        </div>
      </div>

      {/* ── Expanded details ────────────────────────────────────────────── */}
      {expanded && (
        <div className="px-4 pb-2 space-y-2">
          <DetailRow
            icon={<ShoppingBag className="size-3.5" />}
            label="Buyer"
            value={escrow.buyer}
            chainId={CHAIN_ID}
            highlight={isBuyer}
          />
          <DetailRow
            icon={<User className="size-3.5" />}
            label="Seller"
            value={escrow.seller}
            chainId={CHAIN_ID}
            highlight={isSeller}
          />
          {escrow.fundedAt > 0n && (
            <InfoRow label="Funded at" value={formatDate(escrow.fundedAt)} />
          )}
          {escrow.completedAt > 0n && (
            <InfoRow label="Completed at" value={formatDate(escrow.completedAt)} />
          )}
          {escrow.completedAt > 0n && state === EscrowState.Completed && (
            <InfoRow
              label="Emergency refund available after"
              value={formatDate(escrow.completedAt + 30n * 24n * 3600n)}
            />
          )}
        </div>
      )}

      {/* ── Tx receipt ──────────────────────────────────────────────────── */}
      {txUrl && (
        <div className="px-4 pb-2">
          <a
            href={txUrl}
            target="_blank"
            rel="noreferrer"
            className="inline-flex items-center gap-1 text-xs font-medium"
            style={{ color: 'var(--accent-hover)' }}
          >
            View transaction <ExternalLink className="size-3" />
          </a>
        </div>
      )}

      {/* ── Action buttons ──────────────────────────────────────────────── */}
      {!isTerminal && (isBuyer || isSeller) && (
        <div className="px-4 pb-4 pt-1 space-y-2">
          {canApprove && (
            <TxButton
              onClick={handleApprove}
              isPending={isPending}
              isConfirming={isConfirming}
              label={`Approve ${formatUsdc(escrow.amount)} USDC`}
              pendingLabel="Approving..."
              confirmingLabel="Confirming approval..."
            />
          )}
          {canFund && (
            <TxButton
              onClick={handleFund}
              isPending={isPending}
              isConfirming={isConfirming}
              label={`Fund Escrow — ${formatUsdc(escrow.amount)} USDC`}
              pendingLabel="Funding..."
              confirmingLabel="Confirming funding..."
            />
          )}
          {canComplete && (
            <TxButton
              onClick={handleMarkComplete}
              isPending={isPending}
              isConfirming={isConfirming}
              label="Mark Work Completed"
              pendingLabel="Submitting..."
              confirmingLabel="Confirming..."
            />
          )}
          {canRelease && (
            <TxButton
              onClick={handleRelease}
              isPending={isPending}
              isConfirming={isConfirming}
              label={`Release ${formatUsdc(escrow.amount)} USDC to Seller`}
              pendingLabel="Releasing..."
              confirmingLabel="Confirming release..."
            />
          )}
          {canRefund && (
            <TxButton
              onClick={handleRefund}
              isPending={isPending}
              isConfirming={isConfirming}
              label="Request Refund"
              pendingLabel="Requesting..."
              confirmingLabel="Confirming refund..."
              variant="ghost"
            />
          )}
          {canEmergency && (
            <TxButton
              onClick={handleEmergencyRefund}
              isPending={isPending}
              isConfirming={isConfirming}
              label="Emergency Refund (30-day timeout)"
              pendingLabel="Submitting..."
              confirmingLabel="Confirming..."
              variant="ghost"
            />
          )}
          {canCancel && (
            <TxButton
              onClick={handleCancel}
              isPending={isPending}
              isConfirming={isConfirming}
              label="Cancel Escrow"
              pendingLabel="Cancelling..."
              confirmingLabel="Confirming..."
              variant="danger"
            />
          )}
        </div>
      )}

      {/* ── Terminal state message ───────────────────────────────────────── */}
      {isTerminal && (
        <div className="px-4 pb-4">
          <p className="text-xs" style={{ color: 'var(--muted)' }}>
            {state === EscrowState.Released
              ? 'Funds have been released to the seller.'
              : state === EscrowState.Refunded
              ? 'Funds have been refunded to the buyer.'
              : 'This escrow was cancelled.'}
          </p>
        </div>
      )}
    </article>
  )
}

function DetailRow({
  icon,
  label,
  value,
  chainId,
  highlight,
}: {
  icon: React.ReactNode
  label: string
  value: string
  chainId: number
  highlight: boolean
}) {
  return (
    <div
      className="flex items-center justify-between rounded-xl px-3 py-2"
      style={{
        background: highlight ? 'rgba(16, 97, 166, 0.06)' : 'var(--surface-muted)',
      }}
    >
      <div className="flex items-center gap-1.5" style={{ color: 'var(--muted)' }}>
        {icon}
        <span className="text-xs font-medium">{label}</span>
        {highlight && (
          <span
            className="text-xs font-semibold"
            style={{ color: 'var(--accent-hover)' }}
          >
            (you)
          </span>
        )}
      </div>
      <a
        href={buildAddressExplorerUrl(chainId, value)}
        target="_blank"
        rel="noreferrer"
        className="mono text-xs flex items-center gap-1"
        style={{ color: 'var(--ink-2)' }}
      >
        {formatAddress(value)}
        <ExternalLink className="size-2.5" />
      </a>
    </div>
  )
}

function InfoRow({ label, value }: { label: string; value: string }) {
  return (
    <div
      className="flex items-center justify-between rounded-xl px-3 py-2"
      style={{ background: 'var(--surface-muted)' }}
    >
      <span className="text-xs font-medium" style={{ color: 'var(--muted)' }}>{label}</span>
      <span className="text-xs tabular-nums" style={{ color: 'var(--ink-2)' }}>{value}</span>
    </div>
  )
}
