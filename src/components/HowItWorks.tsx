import { PlusCircle, Banknote, CheckCircle2, SendHorizonal } from 'lucide-react'

const STEPS = [
  {
    icon: PlusCircle,
    title: 'Create',
    desc: 'Buyer creates an escrow with the seller address, amount, and deal description.',
  },
  {
    icon: Banknote,
    title: 'Fund',
    desc: 'Buyer deposits USDC. Funds are locked in the smart contract.',
  },
  {
    icon: CheckCircle2,
    title: 'Complete',
    desc: 'Seller delivers the work and marks the escrow as completed.',
  },
  {
    icon: SendHorizonal,
    title: 'Release',
    desc: 'Buyer releases the locked USDC directly to the seller.',
  },
]

export function HowItWorks() {
  return (
    <section
      className="rounded-3xl p-5"
      style={{
        background: 'var(--surface)',
        border: '1px solid var(--border)',
      }}
    >
      <h3 className="display mb-4 text-sm font-bold" style={{ color: 'var(--ink)' }}>
        How it works
      </h3>
      <div className="space-y-3">
        {STEPS.map((step, i) => (
          <div key={step.title} className="flex items-start gap-3">
            <div
              className="mt-0.5 flex size-7 shrink-0 items-center justify-center rounded-xl"
              style={{ background: 'var(--surface-muted)' }}
            >
              <step.icon className="size-3.5" style={{ color: 'var(--accent)' }} />
            </div>
            <div>
              <p className="text-xs font-semibold" style={{ color: 'var(--ink)' }}>
                {i + 1}. {step.title}
              </p>
              <p className="mt-0.5 text-xs leading-relaxed" style={{ color: 'var(--muted)' }}>
                {step.desc}
              </p>
            </div>
          </div>
        ))}
      </div>
    </section>
  )
}
