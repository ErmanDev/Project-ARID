import { useEffect, useMemo, useState } from 'react'
import { Navigate } from 'react-router-dom'
import { areaById, DEFAULT_AREA_ID, inArea } from '../areas'
import { useAuth } from '../auth'
import { FilterBar } from '../components/FilterBar'
import { buildHotspots } from '../components/HotspotLayer'
import { Leaderboard } from '../components/Leaderboard'
import { LiveMap } from '../components/LiveMap'
import { ReportDetail } from '../components/ReportDetail'
import { StatsPanel } from '../components/StatsPanel'
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

export function MonitorPage() {
  const auth = useAuth()
  const online = useOnline()
  const { reports, updatedAt, error } = useReports(Boolean(auth.user && auth.isStaff))
  const users = useUsers(Boolean(auth.user && auth.isStaff))
  const [filters, setFilters] = useState<Filters>(INITIAL)
  const [selectedId, setSelectedId] = useState<string | null>(null)
  const [tick, setTick] = useState(0)

  useEffect(() => {
    const id = window.setInterval(() => setTick((value) => value + 1), 10000)
    return () => window.clearInterval(id)
  }, [])

  const area = areaById(filters.areaId)
  const visible = useMemo(() => {
    return reports.filter((report) => {
      if (!inArea(report.latitude, report.longitude, area)) return false
      if (!filters.risks.includes(report.riskLevel)) return false
      if (filters.classification !== 'all' && report.classification !== filters.classification) {
        return false
      }
      return inRange(report, filters.range)
    })
  }, [reports, filters, area])

  const riskCounts = useMemo(() => {
    const inStudy = reports.filter((report) => {
      if (!inArea(report.latitude, report.longitude, area)) return false
      if (filters.classification !== 'all' && report.classification !== filters.classification) {
        return false
      }
      return inRange(report, filters.range)
    })
    return {
      all: inStudy.length,
      red: inStudy.filter((report) => report.riskLevel === 'red').length,
      yellow: inStudy.filter((report) => report.riskLevel === 'yellow').length,
      green: inStudy.filter((report) => report.riskLevel === 'green').length,
    }
  }, [reports, area, filters.classification, filters.range])

  const selected = visible.find((report) => report.id === selectedId) ?? null
  const usersById = useMemo(
    () => new Map(users.map((user) => [user.id, user])),
    [users],
  )
  const hotspotCount = buildHotspots(visible).length

  if (auth.loading) {
    return (
      <div className="flex h-full items-center justify-center bg-background text-muted">
        Checking access…
      </div>
    )
  }
  if (!auth.user) return <Navigate to="/login" replace />
  if (!auth.isStaff) return <Navigate to="/denied" replace />

  return (
    <div className="flex h-full flex-col bg-background">
      {useMockData ? (
        <div className="bg-secondary px-4 py-2 text-sm text-white">
          Showing mock reports for UI work. Set <code>VITE_USE_MOCK_DATA=false</code> in{' '}
          <code>dashboard/.env</code> when Firestore sync is ready.
        </div>
      ) : null}
      {!online ? (
        <div className="bg-primary px-4 py-2 text-sm text-white">
          Connection lost. Reconnecting… This dashboard needs internet to show live reports.
        </div>
      ) : null}
      <header className="flex flex-wrap items-center justify-between gap-3 border-b border-divider bg-primary px-4 py-3 text-white">
        <div className="flex items-center gap-3">
          <img src="/arid-logo.png" alt="" className="h-10 w-10" />
          <div>
            <div className="text-sm font-semibold tracking-wide">A.R.I.D.</div>
            <div className="text-xs text-white/80">Live breeding-site monitoring</div>
          </div>
        </div>
        <div className="flex items-center gap-4 text-sm">
          <span className="inline-flex items-center gap-2">
            <span className="h-2 w-2 rounded-full bg-white" />
            {formatAgo(updatedAt)}
            <span className="hidden text-white/70 sm:inline" data-tick={tick}>
              {updatedAt ? updatedAt.toLocaleTimeString() : ''}
            </span>
          </span>
          {useMockData ? (
            <span className="text-white/80">Mock staff</span>
          ) : (
            <button type="button" className="text-white/90" onClick={() => void auth.signOut()}>
              Sign out
            </button>
          )}
        </div>
      </header>
      <div className="border-b border-divider bg-surface px-4 py-3">
        <FilterBar
          filters={filters}
          onChange={setFilters}
          hotspotCount={hotspotCount}
          counts={riskCounts}
        />
        {error ? <p className="mt-2 text-sm text-ink">{error}</p> : null}
      </div>
      <div className="grid min-h-0 flex-1 grid-cols-1 lg:grid-cols-[minmax(0,1fr)_360px]">
        <div className="min-h-[55vh] lg:min-h-0">
          <LiveMap
            area={area}
            reports={visible}
            selectedId={selectedId}
            onSelect={setSelectedId}
            showMarkers={filters.showMarkers}
            showHeatmap={filters.showHeatmap}
            showHotspots={filters.showHotspots}
          />
        </div>
        <aside className="space-y-4 overflow-y-auto border-t border-divider bg-background p-4 lg:border-l lg:border-t-0">
          <section>
            <h2 className="mb-2 text-sm font-semibold text-ink">Area snapshot</h2>
            <StatsPanel reports={visible} />
          </section>
          <section className="rounded-xl border border-divider bg-surface p-4">
            {selected && auth.user ? (
              <ReportDetail
                report={selected}
                reporter={usersById.get(selected.userId)}
                staffUid={auth.user.uid}
                onClose={() => setSelectedId(null)}
              />
            ) : (
              <p className="text-sm text-muted">
                Select a marker to inspect a synced report. New reports appear here as the mobile
                app syncs — no refresh needed.
              </p>
            )}
          </section>
          <section>
            <h2 className="mb-2 text-sm font-semibold text-ink">Top contributors</h2>
            <Leaderboard users={users} />
          </section>
        </aside>
      </div>
    </div>
  )
}
