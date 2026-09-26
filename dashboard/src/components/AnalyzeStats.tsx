import type { ReactNode } from 'react'
import type { ClassificationResult } from '../services/detection/classifier'
import { IconCheck, IconMosquito } from './icons'
import { Skeleton } from './ui'

/**
 * The two answers worth reading first, as a compact strip in the photo header:
 * how many containers the detector boxed, and what the classifier called the
 * scene as a whole.
 *
 * They were two large tiles above the photo; as chips they say the same thing
 * in one line, which is what lets the whole Analyze page fit a laptop screen
 * without scrolling.
 *
 * Both chips are status surfaces, so both are allowed a tint - and both ship an
 * icon, because a tinted shape must never rely on colour alone to say what
 * state it is in. Green keeps its app-wide meaning (non-breeding / all clear)
 * and is never spent on a neutral measurement.
 */

type Tone = 'finding' | 'clear'

const TONE: Record<Tone, string> = {
  finding: 'border-alert-edge bg-alert-tint text-alert-ink',
  clear: 'border-risk-green-edge bg-risk-green-tint text-risk-green-ink',
}

function Chip({
  tone,
  icon,
  label,
  children,
}: {
  tone: Tone
  icon: ReactNode
  /** Spoken and shown as a tooltip; the visible text is the value itself. */
  label: string
  children: ReactNode
}) {
  return (
    <div
      className={`flex items-center gap-2 rounded-full border py-1 pl-1 pr-3 text-sm shadow-xs ${TONE[tone]}`}
      title={label}
    >
      <span
        aria-hidden="true"
        className={`grid size-6 shrink-0 place-items-center rounded-full text-white ${
          tone === 'finding' ? 'bg-alert-solid' : 'bg-risk-green-solid'
        }`}
      >
        {icon}
      </span>
      <dt className="sr-only">{label}</dt>
      <dd className="whitespace-nowrap font-semibold">{children}</dd>
    </div>
  )
}

export function AnalyzeStatsSkeleton() {
  return (
    <div className="flex flex-wrap gap-2" aria-hidden="true">
      <Skeleton className="h-8 w-36 rounded-full" />
      <Skeleton className="h-8 w-44 rounded-full" />
    </div>
  )
}

export function AnalyzeStats({
  count,
  verdict,
}: {
  count: number
  verdict: ClassificationResult | null
}) {
  const breeding = verdict?.label === 'Breeding'
  return (
    <dl className="flex flex-wrap gap-2">
      <Chip
        tone={count > 0 ? 'finding' : 'clear'}
        icon={count > 0 ? <IconMosquito size={14} /> : <IconCheck size={14} />}
        label="Containers that can hold water"
      >
        <span data-numeric>{count}</span> potential {count === 1 ? 'spot' : 'spots'}
      </Chip>
      {verdict ? (
        <Chip
          tone={breeding ? 'finding' : 'clear'}
          icon={breeding ? <IconMosquito size={14} /> : <IconCheck size={14} />}
          label="Whole-scene verdict from the same classifier as the mobile app"
        >
          {breeding ? 'Breeding site' : 'Non-breeding site'}{' '}
          <span data-numeric className="font-medium opacity-80">
            {Math.round(verdict.confidence * 100)}%
          </span>
        </Chip>
      ) : null}
    </dl>
  )
}
