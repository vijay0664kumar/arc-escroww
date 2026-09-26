import { useState } from 'react'
import { useAccount } from 'wagmi'
import { Plus, ShieldCheck, ExternalLink } from 'lucide-react'

import { Header } from './components/Header'
import { NetworkGuard } from './components/NetworkGuard'
import { CreateEscrowSheet } from './components/CreateEscrowSheet'
import { EscrowList } from './components/EscrowList'
import { HowItWorks } from './components/HowItWorks'
import { ConnectKitButton } from 'connectkit'
import { ARC_ESCROW_ADDRESS } from './contracts/arcEscrow'
import { buildAddressExplorerUrl } from './onchain-facts'
import { formatAddress } from './utils/escrow'

const CHAIN_ID = 5042002

export default function App() {
  const { isConnected } = useAccount()
  const [sheetOpen, setSheetOpen] = useState(false)
  const [refreshTrigger, setRefreshTrigger] = useState(0)

  function handleCreated() {
    setSheetOpen(false)
    setRefreshTrigger(t => t + 1)
  }

  return (
    <div className="min-h-dvh" style={{ background: 'var(--bg-gradient)' }}>
      <NetworkGuard>
        <Header />

        <main className="mx-auto max-w-md px-4 pb-24 pt-6 space-y-5">

          {/* ── Hero card ─────────────────────────────────────────────── */}
          <section
            className="rounded-3xl p-5"
            style={{
              background: 'var(--surface)',
              border: '1px solid var(--border)',
              backdropFilter: 'blur(20px)',
            }}
          >
            <div className="flex items-center gap-3 mb-4">
              <div
                className="flex size-11 items-center justify-center rounded-2xl"
                style={{ background: 'var(--ink)' }}
              >
                <ShieldCheck className="size-5 text-white" />
              </div>
              <div>
                <h1 className="display text-xl font-bold" style={{ color: 'var(--ink)' }}>
                  Arc Escrow
                </h1>
                <p className="text-xs" style={{ color: 'var(--muted)' }}>
                  Non-custodial USDC escrow on Arc Testnet
                </p>
              </div>
            </div>

            <p className="text-sm leading-relaxed mb-5" style={{ color: 'var(--ink-2)' }}>
              Lock USDC in a smart contract. Funds are released only when both parties agree — no middleman, no trust required.
            </p>

            {isConnected ? (
              <button
                onClick={() => setSheetOpen(true)}
                className="w-full flex items-center justify-center gap-2 rounded-2xl py-3.5 text-sm font-semibold text-white transition-all hover:scale-[1.01] active:scale-[0.99]"
                style={{ background: 'var(--ink)' }}
              >
                <Plus className="size-4" />
                New Escrow
              </button>
            ) : (
              <ConnectKitButton.Custom>
                {({ show }) => (
                  <button
                    onClick={show}
                    className="w-full rounded-2xl py-3.5 text-sm font-semibold text-white transition-all hover:scale-[1.01] active:scale-[0.99]"
                    style={{ background: 'var(--ink)' }}
                  >
                    Connect Wallet to Start
                  </button>
                )}
              </ConnectKitButton.Custom>
            )}
          </section>

          {/* ── Contract info ─────────────────────────────────────────── */}
          <div
            className="flex items-center justify-between rounded-2xl px-4 py-3"
            style={{
              background: 'rgba(16, 97, 166, 0.06)',
              border: '1px solid rgba(16, 97, 166, 0.12)',
            }}
          >
            <div>
              <p className="text-xs font-semibold" style={{ color: 'var(--accent-hover)' }}>
                Smart Contract
              </p>
              <p className="mono text-xs mt-0.5" style={{ color: 'var(--ink-2)' }}>
                {formatAddress(ARC_ESCROW_ADDRESS)}
              </p>
            </div>
            <a
              href={buildAddressExplorerUrl(CHAIN_ID, ARC_ESCROW_ADDRESS)}
              target="_blank"
              rel="noreferrer"
              className="flex items-center gap-1 text-xs font-medium"
              style={{ color: 'var(--accent-hover)' }}
            >
              ArcScan <ExternalLink className="size-3" />
            </a>
          </div>

          {/* ── Escrow list ───────────────────────────────────────────── */}
          {isConnected ? (
            <EscrowList refreshTrigger={refreshTrigger} />
          ) : (
            <HowItWorks />
          )}

          {/* ── How it works (always shown at bottom when connected) ──── */}
          {isConnected && <HowItWorks />}

        </main>
      </NetworkGuard>

      {/* ── Create escrow sheet ───────────────────────────────────────── */}
      <CreateEscrowSheet
        open={sheetOpen}
        onClose={() => setSheetOpen(false)}
        onCreated={handleCreated}
      />
    </div>
  )
}
