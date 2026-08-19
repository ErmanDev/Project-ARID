import type { RiskLevel } from '../types'

const LABELS: Record<RiskLevel, string> = {
  red: 'High risk',
  yellow: 'Moderate',
  green: 'Low risk',
}

export function RiskBadge({ level }: { level: RiskLevel }) {
  const color =
    level === 'red'
      ? 'text-risk-red border-risk-red bg-risk-red/15'
      : level === 'yellow'
        ? 'text-risk-yellow border-risk-yellow bg-risk-yellow/15'
        : 'text-risk-green border-risk-green bg-risk-green/15'
  return (
    <span className={`inline-flex rounded-full border px-2.5 py-0.5 text-xs font-semibold ${color}`}>
      {LABELS[level]}
    </span>
  )
}
