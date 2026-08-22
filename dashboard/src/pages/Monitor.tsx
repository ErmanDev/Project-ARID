import { useEffect, useMemo, useState } from 'react'
import { Navigate } from 'react-router-dom'
import { areaById, DEFAULT_AREA_ID, inArea } from '../areas'
import { useAuth } from '../auth'
import { FilterBar } from '../components/FilterBar'
import { buildHotspots } from '../components/HotspotLayer'
import { IconInfo, IconOffline, IconPin } from '../components/icons'
import { Leaderboard } from '../components/Leaderboard'
import { LiveMap } from '../components/LiveMap'
import { ReportDetail } from '../components/ReportDetail'
import { StatsPanel, StatsPanelSkeleton } from '../components/StatsPanel'
import { Alert, Button, EmptyState, SectionHeading, Skeleton } from '../components/ui'
import { ThemeToggle } from '../components/ThemeToggle'
import { formatAgo } from '../format'
import { useOnline, useReports, useUsers } from '../hooks'
import { useMockData } from '../config'
import type { Filters, Report } from '../types'

const INITIAL: Filters = {
  areaId: DEFAULT_AREA_ID,
  risks: ['red', 'yellow', 'green'],
  classification: 'all',
  range: 'all',
  showMarkers: true,
  showHeatmap: false,
  showHotspots: true,
}

function inRange(report: Report, range: Filters['range']): boolean {
  if (range === 'all') return true
  const captured = new Date(report.capturedAt).getTime()
  const hours = range === '24h' ? 24 : range === '7d' ? 24 * 7 : 24 * 30
  return Date.now() - captured <= hours * 60 * 60 * 1000
}

function isDefaultFilters(filters: Filters): boolean {
  return (
    filters.risks.length === 3 &&
    filters.classification === 'all' &&
    filters.range === 'all'
  )
}

/** Connection state as one dot plus one phrase, announced politely on change. */
function LiveStatus({
  online,
  updatedAt,
}: {
  online: boolean
  updatedAt: Date | null
}) {
  const stale = updatedAt ? Date.now() - updatedAt.getTime() > 120_000 : true
  const tone = !online
    ? 'bg-risk-red-solid'
    : stale
      ? 'bg-risk-yellow-solid'
      : 'bg-risk-green-solid'

  return (
    <p
      className="inline-flex items-center gap-2 text-sm text-ink-2"
      aria-live="polite"
    >
      <span className={`size-2 rounded-full ${tone}`} aria-hidden="true" />
      <span className="sr-only">Data status: </span>
      {online ? formatAgo(updatedAt) : 'offline'}
    </p>
  )
}

export function MonitorPage() {
  const auth = useAuth()
  const online = useOnline()
  const authorized = Boolean(auth.user && auth.isStaff)
  const { reports, updatedAt, error, loading } = useReports(authorized)
  const users = useUsers(authorized)
  const [filters, setFilters] = useState<Filters>(INITIAL)
  const [selectedId, setSelectedId] = useState<string | null>(null)
  const [, setTick] = useState(0)

  // Keeps the relative "3m ago" label honest without touching the data.
  useEffect(() => {
    const id = window.setInterval(() => setTick((value) => value + 1), 10_000)
    return () => window.clearInterval(id)
  }, [])

  const area = areaById(filters.areaId)

  const inScope = useMemo(
    () =>
      reports.filter((report) => {
        if (!inArea(report.latitude, report.longitude, area)) return false
        if (
          filters.classification !== 'all' &&
          report.classification !== filters.classification
        ) {
          return false
        }
        return inRange(report, filters.range)
      }),
    [reports, area, filters.classification, filters.range],
  )

  const visible = useMemo(
    () => inScope.filter((report) => filters.risks.includes(report.riskLevel)),
    [inScope, filters.risks],
  )

  const riskCounts = useMemo(
    () => ({
      all: inScope.length,
      red: inScope.filter((report) => report.riskLevel === 'red').length,
      yellow: inScope.filter((report) => report.riskLevel === 'yellow').length,
      green: inScope.filter((report) => report.riskLevel === 'green').length,
    }),
    [inScope],
  )

  const usersById = useMemo(
    () => new Map(users.map((user) => [user.id, user])),
    [users],
  )
  const hotspotCount = buildHotspots(visible).length

  // Resolved against every report, not just the visible ones, so a filter
  // change explains itself instead of silently emptying the panel.
  const selected = selectedId
    ? (reports.find((report) => report.id === selectedId) ?? null)
    : null
  const selectedHidden =
    selected !== null && !visible.some((report) => report.id === selected.id)

  if (auth.loading) {
    return (
      <div className="grid h-full place-items-center bg-bg">
        <p className="flex items-center gap-2 text-base text-muted">
          <span className="size-2 animate-pulse rounded-full bg-primary" />
          Checking access…
        </p>
      </div>
    )
  }
  if (!auth.user) return <Navigate to="/login" replace />
  if (!auth.isStaff) return <Navigate to="/denied" replace />

  return (
    <div className="flex h-full flex-col bg-bg">
      <header className="flex flex-wrap items-center justify-between gap-x-4 gap-y-2 border-b border-border bg-surface px-4 py-2.5">
        <div className="flex items-center gap-2.5">
          <img src="/arid-logo.png" alt="" className="size-8 shrink-0" />
          <div>
            <h1 className="text-md font-semibold tracking-tight text-ink">
              A.R.I.D.
            </h1>
            <p className="text-xs text-muted">Breeding-site monitoring</p>
          </div>
        </div>
        <div className="flex items-center gap-4">
          <LiveStatus online={online} updatedAt={updatedAt} />
          <ThemeToggle />
          {useMockData ? (
            <span className="rounded-full border border-border bg-sunken px-2 py-0.5 text-xs font-medium text-ink-2">
              Mock staff
            </span>
          ) : (
            <Button size="sm" variant="ghost" onClick={() => void auth.signOut()}>
              Sign out
            </Button>
          )}
        </div>
      </header>

      {useMockData || !online || error ? (
        <div className="space-y-2 border-b border-border bg-panel px-4 py-2.5">
          {useMockData ? (
            <Alert tone="info" icon={<IconInfo size={16} />}>
              Showing mock reports for UI work. Set{' '}
              <code>VITE_USE_MOCK_DATA=false</code> in <code>dashboard/.env</code>{' '}
              when Firestore sync is ready.
            </Alert>
          ) : null}
          {!online ? (
            <Alert tone="warning" live icon={<IconOffline size={16} />}>
              Connection lost. Showing the last data received — this dashboard
              needs internet for live reports.
            </Alert>
          ) : null}
          {error ? (
            <Alert tone="error" live>
              <span className="font-medium">Live updates stopped.</span> The map
              is showing the last data received. {error}
            </Alert>
          ) : null}
        </div>
      ) : null}

      <div className="border-b border-border bg-panel px-4 py-2.5">
        <FilterBar
          filters={filters}
          onChange={setFilters}
          hotspotCount={hotspotCount}
          counts={riskCounts}
        />
      </div>

      <div className="grid min-h-0 flex-1 grid-cols-1 lg:grid-cols-[minmax(0,1fr)_380px]">
        <div className="min-h-[55vh] lg:min-h-0">
          <LiveMap
            area={area}
            reports={visible}
            selectedId={selectedId}
            onSelect={setSelectedId}
            showMarkers={filters.showMarkers}
            showHeatmap={filters.showHeatmap}
            showHotspots={filters.showHotspots}
            filtered={!isDefaultFilters(filters) || inScope.length !== reports.length}
          />
        </div>

        <aside
          aria-label="Area detail"
          className="min-h-0 space-y-5 overflow-y-auto border-t border-border bg-panel p-4 lg:border-l lg:border-t-0"
        >
          {/* A selected report outranks the summary: it is what the operator
              just asked for, and it should not require a scroll. */}
          {selected ? (
            <section>
              <div className="overflow-hidden rounded-card border border-border bg-surface shadow-sm">
                {selectedHidden ? (
                  <Alert tone="warning" className="m-3">
                    This report no longer matches the current filters. It stays
                    open until you close it.
                  </Alert>
                ) : null}
                {auth.user ? (
                  <ReportDetail
                    report={selected}
                    reporter={usersById.get(selected.userId)}
                    staffUid={auth.user.uid}
                    onClose={() => setSelectedId(null)}
                  />
                ) : null}
              </div>
            </section>
          ) : null}

          <section>
            <SectionHeading aside={area.name}>Area snapshot</SectionHeading>
            {loading ? <StatsPanelSkeleton /> : <StatsPanel reports={visible} />}
          </section>

          {!selected ? (
            <section>
              <div className="rounded-card border border-dashed border-border bg-surface/60">
                <EmptyState icon={<IconPin size={20} />} title="No report selected">
                  Choose a marker on the map to inspect its photo, confidence and
                  GPS accuracy, and to set a review status. New reports appear as
                  the mobile app syncs — no refresh needed.
                </EmptyState>
              </div>
            </section>
          ) : null}

          <section>
            <SectionHeading aside={users.length > 0 ? `${users.length} total` : undefined}>
              Top contributors
            </SectionHeading>
            {loading ? (
              <div className="space-y-2 rounded-card border border-border bg-surface p-3">
                <Skeleton className="h-9 w-full" />
                <Skeleton className="h-9 w-full" />
                <Skeleton className="h-9 w-full" />
              </div>
            ) : (
              <Leaderboard users={users} />
            )}
          </section>
        </aside>
      </div>
    </div>
  )
}
