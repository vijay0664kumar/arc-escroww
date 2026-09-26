import { useState, useCallback } from 'react'
import { useAccount, useWriteContract, useWaitForTransactionReceipt } from 'wagmi'
import { parseUnits, isAddress } from 'viem'
import { motion, AnimatePresence } from 'framer-motion'
import { X } from 'lucide-react'
import { toast } from 'sonner'

import { ARC_ESCROW_CONTRACT } from '../contracts/arcEscrow'
import { TxButton } from './TxButton'
import { parseOnchainError } from '../utils/escrow'

interface CreateEscrowSheetProps {
  open: boolean
  onClose: () => void
  onCreated: () => void
}

const SPRING = { type: 'spring' as const, stiffness: 400, damping: 40 }

export function CreateEscrowSheet({ open, onClose, onCreated }: CreateEscrowSheetProps) {
  const { address } = useAccount()
  const [seller, setSeller] = useState('')
  const [amount, setAmount] = useState('')
  const [description, setDescription] = useState('')
  const [errors, setErrors] = useState<Record<string, string>>({})

  const { writeContract, data: txHash, isPending, reset } = useWriteContract()
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash: txHash })

  // When the transaction confirms, notify and close
  if (isSuccess && txHash) {
    // Only fire once — wagmi resets hash on next write
    toast.success('Escrow created successfully!')
    reset()
    onCreated()
  }

  const validate = useCallback(() => {
    const errs: Record<string, string> = {}
    if (!isAddress(seller)) errs.seller = 'Enter a valid wallet address (0x…)'
    if (seller.toLowerCase() === address?.toLowerCase()) errs.seller = 'Seller cannot be your own address'
    if (!amount || parseFloat(amount) <= 0) errs.amount = 'Amount must be greater than 0'
    if (!description.trim()) errs.description = 'Please describe the deal'
    return errs
  }, [seller, amount, description, address])

  function handleCreate() {
    const errs = validate()
    if (Object.keys(errs).length > 0) { setErrors(errs); return }
    setErrors({})
    try {
      const rawAmount = parseUnits(amount, 6)
      writeContract({
        ...ARC_ESCROW_CONTRACT,
        functionName: 'createEscrow',
        args: [seller as `0x${string}`, rawAmount, description],
      })
    } catch (err) {
      toast.error(parseOnchainError(err))
    }
  }

  return (
    <AnimatePresence>
      {open && (
        <motion.div
          className="fixed inset-0 z-50 flex items-end justify-center"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          onClick={onClose}
        >
          <div className="absolute inset-0 bg-black/20 backdrop-blur-sm" />
          <motion.section
            className="relative w-full max-w-md overflow-hidden rounded-t-3xl"
            style={{
              background: 'rgba(255,255,255,0.92)',
              backdropFilter: 'blur(48px) saturate(200%)',
              WebkitBackdropFilter: 'blur(48px) saturate(200%)',
            }}
            initial={{ y: '100%' }}
            animate={{ y: 0 }}
            exit={{ y: '100%' }}
            transition={SPRING}
            onClick={e => e.stopPropagation()}
          >
            {/* Spectral strip */}
            <div
              className="h-1 w-full"
              style={{
                background:
                  'linear-gradient(90deg, #acc6e9 0%, #b8c8e8 25%, #c8d8f0 50%, #acc6e9 75%, #85b1ed 100%)',
              }}
            />

            {/* Drag handle */}
            <div className="flex justify-center pt-3 pb-1">
              <div className="h-1 w-10 rounded-full bg-black/10" />
            </div>

            <div className="px-5 pb-8 pt-3">
              <div className="mb-5 flex items-center justify-between">
                <h2 className="display text-lg font-bold" style={{ color: 'var(--ink)' }}>
                  Create Escrow
                </h2>
                <button
                  onClick={onClose}
                  className="rounded-xl p-1.5 transition-colors"
                  style={{ color: 'var(--muted)' }}
                >
                  <X className="size-5" />
                </button>
              </div>

              <div className="space-y-4">
                <Field
                  label="Seller wallet address"
                  error={errors.seller}
                >
                  <input
                    type="text"
                    value={seller}
                    onChange={e => setSeller(e.target.value)}
                    placeholder="0x..."
                    className="mono w-full rounded-2xl px-4 py-3 text-sm outline-none transition-colors"
                    style={{
                      background: 'var(--surface-muted)',
                      color: 'var(--ink)',
                      border: errors.seller ? '1px solid var(--danger)' : '1px solid transparent',
                    }}
                    spellCheck={false}
                  />
                </Field>

                <Field
                  label="Payment amount (USDC)"
                  error={errors.amount}
                >
                  <div
                    className="flex items-center rounded-2xl px-4 py-3 gap-3"
                    style={{
                      background: 'var(--surface-muted)',
                      border: errors.amount ? '1px solid var(--danger)' : '1px solid transparent',
                    }}
                  >
                    <input
                      inputMode="decimal"
                      type="text"
                      value={amount}
                      onChange={e => {
                        const v = e.target.value.replace(/[^0-9.]/g, '')
                        if (v === '' || /^\d*\.?\d{0,6}$/.test(v)) setAmount(v)
                      }}
                      placeholder="0.00"
                      className="display w-full bg-transparent text-2xl font-bold tabular-nums outline-none placeholder:opacity-30"
                      style={{ color: 'var(--ink)' }}
                    />
                    <span className="text-sm font-semibold shrink-0" style={{ color: 'var(--muted)' }}>
                      USDC
                    </span>
                  </div>
                </Field>

                <Field
                  label="Deal description"
                  error={errors.description}
                >
                  <textarea
                    value={description}
                    onChange={e => setDescription(e.target.value)}
                    placeholder="Describe the work or deliverable…"
                    rows={3}
                    className="w-full rounded-2xl px-4 py-3 text-sm outline-none resize-none"
                    style={{
                      background: 'var(--surface-muted)',
                      color: 'var(--ink)',
                      border: errors.description ? '1px solid var(--danger)' : '1px solid transparent',
                    }}
                  />
                </Field>

                <TxButton
                  onClick={handleCreate}
                  isPending={isPending}
                  isConfirming={isConfirming}
                  label="Create Escrow"
                  pendingLabel="Creating..."
                  confirmingLabel="Confirming..."
                />

                <p className="text-center text-xs" style={{ color: 'var(--subtle)' }}>
                  Funds are locked until you and the seller complete the deal.
                </p>
              </div>
            </div>
          </motion.section>
        </motion.div>
      )}
    </AnimatePresence>
  )
}

function Field({
  label,
  error,
  children,
}: {
  label: string
  error?: string
  children: React.ReactNode
}) {
  return (
    <div>
      <label className="mb-1.5 block text-xs font-semibold" style={{ color: 'var(--muted)' }}>
        {label}
      </label>
      {children}
      {error && (
        <p className="mt-1 text-xs" style={{ color: 'var(--danger)' }}>
          {error}
        </p>
      )}
    </div>
  )
}
