import { Loader2 } from 'lucide-react'

interface TxButtonProps {
  onClick: () => void
  disabled?: boolean
  isPending?: boolean
  isConfirming?: boolean
  label: string
  pendingLabel?: string
  confirmingLabel?: string
  variant?: 'primary' | 'danger' | 'ghost'
  className?: string
}

const VARIANTS = {
  primary: {
    base: 'text-white',
    bg: 'var(--accent)',
    hover: 'var(--accent-hover)',
  },
  danger: {
    base: 'text-white',
    bg: 'var(--danger)',
    hover: '#a02040',
  },
  ghost: {
    base: '',
    bg: 'var(--surface-muted)',
    hover: 'var(--border)',
  },
}

export function TxButton({
  onClick,
  disabled = false,
  isPending = false,
  isConfirming = false,
  label,
  pendingLabel = 'Confirm in wallet...',
  confirmingLabel = 'Confirming...',
  variant = 'primary',
  className = '',
}: TxButtonProps) {
  const v = VARIANTS[variant]
  const busy = isPending || isConfirming
  const isDisabled = disabled || busy

  return (
    <button
      onClick={onClick}
      disabled={isDisabled}
      className={`w-full rounded-2xl py-3.5 text-sm font-semibold transition-all
        hover:scale-[1.01] active:scale-[0.99]
        disabled:cursor-not-allowed disabled:opacity-40
        flex items-center justify-center gap-2 ${v.base} ${className}`}
      style={{ background: v.bg }}
    >
      {isPending ? (
        <>
          <Loader2 className="size-4 animate-spin" />
          {pendingLabel}
        </>
      ) : isConfirming ? (
        <>
          <Loader2 className="size-4 animate-spin" />
          {confirmingLabel}
        </>
      ) : (
        label
      )}
    </button>
  )
}
