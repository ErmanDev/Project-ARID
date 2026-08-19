import type { ReactNode } from 'react'
import { AREAS } from '../areas'
import type { Filters, RiskLevel } from '../types'

type Props = {
  filters: Filters
  onChange: (next: Filters) => void
  hotspotCount: number
  counts: { all: number; red: number; yellow: number; green: number }
}

function Chip({
  active,
  onClick,
  children,
}: {
  active: boolean
  onClick: () => void
  children: ReactNode
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={`rounded-full border px-3 py-1 text-xs font-medium ${
        active
          ? 'border-primary bg-primary/10 text-primary'
          : 'border-divider bg-surface text-muted'
      }`}
    >
      {children}
    </button>
  )
}

export function FilterBar({ filters, onChange, hotspotCount, counts }: Props) {
  const allRisks: RiskLevel[] = ['red', 'yellow', 'green']
  const allActive = allRisks.every((level) => filters.risks.includes(level))
  const only = filters.risks.length === 1 ? filters.risks[0] : null

  function showRisk(level: RiskLevel | 'all') {
    onChange({
      ...filters,
      risks: level === 'all' ? allRisks : [level],
    })
  }

  return (
    <div className="flex flex-wrap items-center gap-2">
      <select
        className="rounded-lg border border-divider bg-surface px-3 py-1.5 text-sm text-ink"
        value={filters.areaId}
        onChange={(event) => onChange({ ...filters, areaId: event.target.value })}
      >
        {AREAS.map((area) => (
          <option key={area.id} value={area.id}>
            {area.name}
          </option>
        ))}
      </select>
      <Chip active={allActive} onClick={() => showRisk('all')}>
        All ({counts.all})
      </Chip>
      <Chip active={only === 'red'} onClick={() => showRisk('red')}>
        High ({counts.red})
      </Chip>
      <Chip active={only === 'yellow'} onClick={() => showRisk('yellow')}>
        Moderate ({counts.yellow})
      </Chip>
      <Chip active={only === 'green'} onClick={() => showRisk('green')}>
        Low ({counts.green})
      </Chip>
      <select
        className="rounded-lg border border-divider bg-surface px-3 py-1.5 text-sm text-ink"
        value={filters.classification}
        onChange={(event) =>
          onChange({
            ...filters,
            classification: event.target.value as Filters['classification'],
          })
        }
      >
        <option value="all">All classes</option>
        <option value="breeding">Breeding</option>
        <option value="nonBreeding">Non-breeding</option>
      </select>
      <select
        className="rounded-lg border border-divider bg-surface px-3 py-1.5 text-sm text-ink"
        value={filters.range}
        onChange={(event) =>
          onChange({ ...filters, range: event.target.value as Filters['range'] })
        }
      >
        <option value="all">All dates</option>
        <option value="24h">Last 24 hours</option>
        <option value="7d">Last 7 days</option>
        <option value="30d">Last 30 days</option>
      </select>
      <Chip
        active={filters.showMarkers}
        onClick={() => onChange({ ...filters, showMarkers: !filters.showMarkers })}
      >
        Markers
      </Chip>
      <Chip
        active={filters.showHeatmap}
        onClick={() => onChange({ ...filters, showHeatmap: !filters.showHeatmap })}
      >
        Heatmap
      </Chip>
      <Chip
        active={filters.showHotspots}
        onClick={() => onChange({ ...filters, showHotspots: !filters.showHotspots })}
      >
        Hotspots{hotspotCount ? ` (${hotspotCount})` : ''}
      </Chip>
    </div>
  )
}
