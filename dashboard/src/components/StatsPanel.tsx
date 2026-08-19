import type { Report } from '../types'

type Stats = {
  total: number
  red: number
  yellow: number
  green: number
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
  let green = 0
  let last24h = 0
  let last7d = 0
  let thisWeek = 0
  let lastWeek = 0
  for (const report of reports) {
    const t = new Date(report.capturedAt).getTime()
    if (report.riskLevel === 'red') red += 1
    if (report.riskLevel === 'yellow') yellow += 1
    if (report.riskLevel === 'green') green += 1
    if (now - t <= day) last24h += 1
    if (now - t <= 7 * day) last7d += 1
    if (t >= startThisWeek) thisWeek += 1
    else if (t >= startLastWeek) lastWeek += 1
  }
  return {
    total: reports.length,
    red,
    yellow,
    green,
    last24h,
    last7d,
    weekDelta: thisWeek - lastWeek,
  }
}

export function StatsPanel({ reports }: { reports: Report[] }) {
  const stats = computeStats(reports)
  const trend =
    stats.weekDelta > 0
      ? `+${stats.weekDelta} vs last week`
      : stats.weekDelta < 0
        ? `${stats.weekDelta} vs last week`
        : 'same as last week'

  return (
    <div className="grid grid-cols-2 gap-2 sm:grid-cols-3">
      <Stat label="Synced reports" value={String(stats.total)} />
      <Stat label="High risk" value={String(stats.red)} />
      <Stat label="Moderate" value={String(stats.yellow)} />
      <Stat label="Low risk" value={String(stats.green)} />
      <Stat label="Last 24h" value={String(stats.last24h)} />
      <Stat label="Last 7d" value={`${stats.last7d} · ${trend}`} />
    </div>
  )
}

function Stat({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-xl border border-divider bg-surface p-3">
      <div className="text-lg font-semibold text-ink">{value}</div>
      <div className="text-xs text-muted">{label}</div>
    </div>
  )
}
