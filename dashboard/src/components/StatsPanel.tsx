import { IconTrendDown, IconTrendFlat, IconTrendUp } from './icons'
import { RiskDot } from './RiskBadge'
import { Skeleton } from './ui'
import type { Report, RiskLevel } from '../types'

type Stats = {
  total: number
  red: number
  yellow: number
  blue: number
  last24h: number
  last7d: number
  weekDelta: number
}

export function computeStats(reports: Report[]): Stats {
  const now = Date.now()
  const day = 24 * 60 * 60 * 1000
  const startThisWeek = now - 7 * day
  const startLastWeek = now - 14 * day
  let red = 0
  let yellow = 0
  let blue = 0
  let last24h = 0
  let last7d = 0
  let thisWeek = 0
  let lastWeek = 0
  for (const report of reports) {
    const t = new Date(report.capturedAt).getTime()
    if (report.riskLevel === 'red') red += 1
    if (report.riskLevel === 'yellow') yellow += 1
    if (report.riskLevel === 'blue') blue += 1
    if (now - t <= day) last24h += 1
    if (now - t <= 7 * day) last7d += 1
    if (t >= startThisWeek) thisWeek += 1
    else if (t >= startLastWeek) lastWeek += 1
  }
  return {
    total: reports.length,
    red,
    yellow,
    blue,
    last24h,
    last7d,
    weekDelta: thisWeek - lastWeek,
  }
}

const RISK_ROWS: Array<{ level: RiskLevel; label: string; bar: string }> = [
  { level: 'red', label: 'High risk', bar: 'bg-risk-red-solid' },
  { level: 'yellow', label: 'Moderate', bar: 'bg-risk-yellow-solid' },
  { level: 'blue', label: 'Non-breeding', bar: 'bg-risk-blue-solid' },
]

export function StatsPanelSkeleton() {
  return (
    <div className="rounded-card border border-border bg-surface p-4">
      <Skeleton className="h-8 w-20" />
      <Skeleton className="mt-3 h-2 w-full" />
      <div className="mt-4 space-y-2.5">
        <Skeleton className="h-4 w-full" />
        <Skeleton className="h-4 w-full" />
        <Skeleton className="h-4 w-full" />
      </div>
    </div>
  )
}

/**
 * A distribution, not a scoreboard. Six equal tiles gave every number the same
 * weight and buried the one thing an operator needs to see first: how much of
 * the visible caseload is high risk.
 */
export function StatsPanel({ reports }: { reports: Report[] }) {
  const stats = computeStats(reports)
  const counts: Record<RiskLevel, number> = {
    red: stats.red,
    yellow: stats.yellow,
    blue: stats.blue,
  }
  const share = (value: number) =>
    stats.total === 0 ? 0 : Math.round((value / stats.total) * 100)

  const TrendIcon =
    stats.weekDelta > 0
      ? IconTrendUp
      : stats.weekDelta < 0
        ? IconTrendDown
        : IconTrendFlat
  // More reports is worse news here, so rising trend reads as risk, not growth.
  const trendTone =
    stats.weekDelta > 0
      ? 'border-risk-red-edge bg-risk-red-tint text-risk-red-ink'
      : stats.weekDelta < 0
        ? 'border-risk-green-edge bg-risk-green-tint text-risk-green-ink'
        : 'border-border bg-sunken text-muted'
  const trendLabel =
    stats.weekDelta === 0
      ? 'level vs last week'
      : `${stats.weekDelta > 0 ? '+' : ''}${stats.weekDelta} vs last week`

  return (
    <div className="rounded-card border border-border bg-surface p-4 shadow-xs">
      <div className="flex items-start justify-between gap-3">
        <div>
          <div
            data-numeric
            className="text-stat font-semibold tracking-tight text-ink"
          >
            {stats.total}
          </div>
          <div className="mt-0.5 text-sm text-muted">
            {stats.total === 1 ? 'report in view' : 'reports in view'}
          </div>
        </div>
        <span
          className={`inline-flex items-center gap-1.5 rounded-full border px-2 py-1 text-xs font-medium ${trendTone}`}
        >
          <TrendIcon size={13} />
          <span data-numeric>{trendLabel}</span>
        </span>
      </div>

      {/* Decorative twin of the list below; the list carries the real values. */}
      <div
        className="mt-3.5 flex h-1.5 gap-px overflow-hidden rounded-full bg-sunken"
        aria-hidden="true"
      >
        {RISK_ROWS.map((row) =>
          counts[row.level] > 0 ? (
            <div
              key={row.level}
              className={`${row.bar} transition-[flex-grow] duration-(--duration-slow) ease-(--ease-out-quart)`}
              style={{ flexGrow: counts[row.level] }}
            />
          ) : null,
        )}
      </div>

      <dl className="mt-3.5 space-y-2">
        {RISK_ROWS.map((row) => (
          <div key={row.level} className="flex items-center gap-2.5 text-base">
            <RiskDot level={row.level} />
            <dt className="flex-1 text-ink-2">{row.label}</dt>
            <dd className="flex items-baseline gap-2">
              <span data-numeric className="font-semibold text-ink">
                {counts[row.level]}
              </span>
              <span
                data-numeric
                className="w-9 text-right text-xs text-muted"
                title={`${share(counts[row.level])}% of reports in view`}
              >
                {share(counts[row.level])}%
              </span>
            </dd>
          </div>
        ))}
      </dl>

      <dl className="mt-3.5 flex gap-6 border-t border-border pt-3">
        <div>
          <dt className="text-xs text-muted">Last 24 hours</dt>
          <dd data-numeric className="mt-0.5 text-md font-semibold text-ink">
            {stats.last24h}
          </dd>
        </div>
        <div>
          <dt className="text-xs text-muted">Last 7 days</dt>
          <dd data-numeric className="mt-0.5 text-md font-semibold text-ink">
            {stats.last7d}
          </dd>
        </div>
      </dl>
    </div>
  )
}
