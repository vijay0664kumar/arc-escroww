import { EscrowState, ESCROW_STATE_LABELS } from '../contracts/arcEscrow'
import { stateColor } from '../utils/escrow'

const COLOR_MAP: Record<string, { bg: string; text: string; dot: string }> = {
  blue:    { bg: 'rgba(16, 97, 166, 0.10)',  text: '#1061a6', dot: '#1061a6' },
  amber:   { bg: 'rgba(146, 96, 10, 0.10)',  text: '#92600a', dot: '#d97706' },
  indigo:  { bg: 'rgba(79, 70, 229, 0.10)',  text: '#4338ca', dot: '#6366f1' },
  green:   { bg: 'rgba(26, 128, 71, 0.10)',  text: '#1a8047', dot: '#16a34a' },
  emerald: { bg: 'rgba(4, 120, 87, 0.10)',   text: '#047857', dot: '#10b981' },
  gray:    { bg: 'rgba(100, 116, 139, 0.10)', text: '#64748b', dot: '#94a3b8' },
  red:     { bg: 'rgba(186, 43, 76, 0.10)',  text: '#ba2b4c', dot: '#e11d48' },
}

interface StateBadgeProps {
  state: EscrowState
  size?: 'sm' | 'md'
}

export function StateBadge({ state, size = 'md' }: StateBadgeProps) {
  const color = stateColor(state)
  const colors = COLOR_MAP[color]
  const label = ESCROW_STATE_LABELS[state] ?? 'Unknown'

  return (
    <span
      className={`inline-flex items-center gap-1.5 rounded-full font-semibold ${
        size === 'sm' ? 'px-2 py-0.5 text-xs' : 'px-3 py-1 text-xs'
      }`}
      style={{ background: colors.bg, color: colors.text }}
    >
      <span
        className="rounded-full"
        style={{
          width: size === 'sm' ? 5 : 6,
          height: size === 'sm' ? 5 : 6,
          background: colors.dot,
          flexShrink: 0,
          display: 'inline-block',
        }}
      />
      {label}
    </span>
  )
}
