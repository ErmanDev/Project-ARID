import type { RiskLevel } from '../types'

const LABELS: Record<RiskLevel, string> = {
  red: 'High risk',
  yellow: 'Moderate',
  blue: 'Non-breeding',
}

/**
 * Risk never rides on colour alone: every badge pairs a hue with its own label,
 * and the dot uses the `-solid` ramp (>=3:1 on both surface and tint) so it
 * stays distinguishable for colour-vision-deficient operators.
 *
 * Text uses the `-ink` ramp, which clears 6.8:1 on its tint. The previous
 * version put the base hue on a 15% wash of itself: 2.06:1 for yellow.
 */
const TONE: Record<RiskLevel, { box: string; dot: string }> = {
  red: {
    box: 'border-risk-red-edge bg-risk-red-tint text-risk-red-ink',
    dot: 'bg-risk-red-solid',
  },
  yellow: {
    box: 'border-risk-yellow-edge bg-risk-yellow-tint text-risk-yellow-ink',
    dot: 'bg-risk-yellow-solid',
  },
  blue: {
    box: 'border-risk-blue-edge bg-risk-blue-tint text-risk-blue-ink',
    dot: 'bg-risk-blue-solid',
  },
}

export function riskLabel(level: RiskLevel): string {
  return LABELS[level]
}

export function RiskDot({ level }: { level: RiskLevel }) {
  return (
    <span
      className={`size-2 shrink-0 rounded-full ${TONE[level].dot}`}
      aria-hidden="true"
    />
  )
}

export function RiskBadge({
  level,
  size = 'md',
}: {
  level: RiskLevel
  size?: 'sm' | 'md'
}) {
  const tone = TONE[level]
  return (
    <span
      className={`inline-flex items-center gap-1.5 rounded-full border font-semibold ${tone.box} ${
        size === 'sm' ? 'px-2 py-0.5 text-xs' : 'px-2.5 py-1 text-sm'
      }`}
    >
      <RiskDot level={level} />
      {LABELS[level]}
    </span>
  )
}
