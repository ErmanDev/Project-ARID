import { AREAS } from '../areas'
import { IconHeat, IconHotspot, IconPin } from './icons'
import { LayerToggle, Segmented, Select, type SegmentOption } from './ui'
import type { Filters, RiskLevel } from '../types'

type Props = {
  filters: Filters
  onChange: (next: Filters) => void
  hotspotCount: number
  counts: { all: number; red: number; yellow: number; blue: number }
}

type RiskChoice = 'all' | RiskLevel

const ALL_RISKS: RiskLevel[] = ['red', 'yellow', 'blue']

function Group({
  label,
  children,
}: {
  label: string
  children: React.ReactNode
}) {
  return (
    // Full-width rows on phones; content-sized from md up. Never flex-1: a
    // stretched group leaves ragged gaps and misaligns against its neighbours.
    <div className="flex w-full min-w-0 flex-wrap items-center gap-2 md:w-auto">
      {/* The label does the separating work a vertical rule used to. A rule
          strands itself at the end of a row whenever the toolbar wraps. */}
      <span className="w-12 shrink-0 text-xs font-medium text-muted md:w-auto">
        {label}
      </span>
      {children}
    </div>
  )
}

/**
 * Three jobs, visually separated: choose the scope (where/when/what), narrow by
 * risk, choose what the map draws. Previously all nine controls sat in one
 * undifferentiated wrap of mixed pills and selects, so nothing read as primary.
 */
export function FilterBar({ filters, onChange, hotspotCount, counts }: Props) {
  const riskChoice: RiskChoice =
    filters.risks.length === 1 ? filters.risks[0] : 'all'

  const riskOptions: SegmentOption<RiskChoice>[] = [
    { value: 'all', label: 'All', meta: counts.all },
    { value: 'red', label: 'High', meta: counts.red, title: 'High risk only' },
    {
      value: 'yellow',
      label: 'Moderate',
      meta: counts.yellow,
      title: 'Moderate risk only',
    },
    { value: 'blue', label: 'Non-breeding', meta: counts.blue, title: 'Non-breeding only' },
  ]

  return (
    <div className="flex flex-wrap items-center gap-x-4 gap-y-2.5">
      <Group label="Scope">
        <Select
          label="Study area"
          value={filters.areaId}
          onChange={(event) => onChange({ ...filters, areaId: event.target.value })}
        >
          {AREAS.map((area) => (
            <option key={area.id} value={area.id}>
              {area.name}
            </option>
          ))}
        </Select>
        <Select
          label="Date range"
          value={filters.range}
          onChange={(event) =>
            onChange({ ...filters, range: event.target.value as Filters['range'] })
          }
        >
          <option value="all">All dates</option>
          <option value="24h">Last 24 hours</option>
          <option value="7d">Last 7 days</option>
          <option value="30d">Last 30 days</option>
        </Select>
        <Select
          label="Classification"
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
        </Select>
      </Group>

      <Group label="Risk">
        <Segmented
          label="Filter by risk level"
          value={riskChoice}
          options={riskOptions}
          onChange={(next) =>
            onChange({
              ...filters,
              risks: next === 'all' ? ALL_RISKS : [next],
            })
          }
        />
      </Group>

      <Group label="Layers">
        <div className="flex flex-wrap items-center gap-1.5">
          <LayerToggle
            pressed={filters.showMarkers}
            onChange={(next) => onChange({ ...filters, showMarkers: next })}
            icon={<IconPin size={15} />}
          >
            Markers
          </LayerToggle>
          <LayerToggle
            pressed={filters.showHeatmap}
            onChange={(next) => onChange({ ...filters, showHeatmap: next })}
            icon={<IconHeat size={15} />}
          >
            Heatmap
          </LayerToggle>
          <LayerToggle
            pressed={filters.showHotspots}
            onChange={(next) => onChange({ ...filters, showHotspots: next })}
            icon={<IconHotspot size={15} />}
            count={hotspotCount}
          >
            Hotspots
          </LayerToggle>
        </div>
      </Group>
    </div>
  )
}
