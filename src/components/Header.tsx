import { ConnectKitButton } from 'connectkit'
import { useAccount } from 'wagmi'
import { arcTestnet } from 'viem/chains'
import { ShieldCheck, AlertTriangle } from 'lucide-react'

const TARGET_CHAIN_ID = arcTestnet.id

export function Header() {
  const { isConnected, chainId } = useAccount()
  const onCorrectChain = !isConnected || chainId === TARGET_CHAIN_ID

  return (
    <header
      className="sticky top-0 z-40 w-full"
      style={{
        background: 'rgba(255,255,255,0.80)',
        backdropFilter: 'blur(20px)',
        borderBottom: '1px solid var(--border)',
      }}
    >
      <div className="mx-auto flex max-w-md items-center justify-between px-4 py-3">
        {/* Logo */}
        <div className="flex items-center gap-2">
          <div
            className="flex size-8 items-center justify-center rounded-xl"
            style={{ background: 'var(--ink)' }}
          >
            <ShieldCheck className="size-4 text-white" />
          </div>
          <div>
            <span className="display text-sm font-bold" style={{ color: 'var(--ink)' }}>
              Arc Escrow
            </span>
            <div className="flex items-center gap-1">
              {onCorrectChain ? (
                <>
                  <span
                    className="inline-block size-1.5 rounded-full"
                    style={{ background: 'var(--success)' }}
                  />
                  <span className="text-xs" style={{ color: 'var(--muted)' }}>
                    Arc Testnet
                  </span>
                </>
              ) : (
                <>
                  <AlertTriangle className="size-3" style={{ color: 'var(--warning)' }} />
                  <span className="text-xs" style={{ color: 'var(--warning)' }}>
                    Wrong network
                  </span>
                </>
              )}
            </div>
          </div>
        </div>

        {/* Wallet */}
        <ConnectKitButton.Custom>
          {({ isConnected, show, truncatedAddress }) => (
            <button
              onClick={show}
              className="rounded-2xl px-4 py-2 text-xs font-semibold transition-all hover:opacity-80"
              style={
                isConnected
                  ? {
                      background: 'var(--surface-muted)',
                      color: 'var(--ink)',
                      border: '1px solid var(--border)',
                    }
                  : {
                      background: 'var(--ink)',
                      color: '#fff',
                    }
              }
            >
              {isConnected ? (
                <span className="mono">{truncatedAddress}</span>
              ) : (
                'Connect Wallet'
              )}
            </button>
          )}
        </ConnectKitButton.Custom>
      </div>
    </header>
  )
}
