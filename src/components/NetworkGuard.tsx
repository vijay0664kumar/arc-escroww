import { useAccount, useSwitchChain } from 'wagmi'
import { arcTestnet } from 'viem/chains'
import { AlertTriangle, RefreshCw } from 'lucide-react'

const TARGET_CHAIN_ID = arcTestnet.id

export function NetworkGuard({ children }: { children: React.ReactNode }) {
  const { isConnected, chainId } = useAccount()
  const { switchChain, isPending } = useSwitchChain()

  if (!isConnected) return <>{children}</>

  if (chainId !== TARGET_CHAIN_ID) {
    return (
      <div className="fixed inset-x-0 top-0 z-50 flex justify-center p-3">
        <div
          className="flex items-center gap-3 rounded-2xl px-4 py-3 text-sm font-medium shadow-lg"
          style={{
            background: 'rgba(186, 43, 76, 0.08)',
            border: '1px solid rgba(186, 43, 76, 0.25)',
            color: 'var(--danger)',
            backdropFilter: 'blur(20px)',
          }}
        >
          <AlertTriangle className="size-4 shrink-0" />
          <span>Wrong network — Arc Testnet required</span>
          <button
            onClick={() => switchChain({ chainId: TARGET_CHAIN_ID })}
            disabled={isPending}
            className="ml-1 flex items-center gap-1.5 rounded-xl px-3 py-1.5 text-xs font-semibold transition-opacity disabled:opacity-50"
            style={{ background: 'var(--danger)', color: '#fff' }}
          >
            <RefreshCw className={`size-3 ${isPending ? 'animate-spin' : ''}`} />
            Switch Network
          </button>
        </div>
      </div>
    )
  }

  return <>{children}</>
}
