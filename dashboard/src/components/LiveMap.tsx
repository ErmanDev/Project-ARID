import { useEffect, useRef } from 'react'
import { MapContainer, Marker, Rectangle, TileLayer, useMap } from 'react-leaflet'
import L from 'leaflet'
import { areaCenter } from '../areas'
import { MAP_ACCENT, riskIcon, TILE_URL } from '../format'
import { useTheme } from '../theme'
import type { Area, Report, RiskLevel } from '../types'
import { HeatLayer } from './HeatLayer'
import { HotspotLayer } from './HotspotLayer'
import { IconSearchOff } from './icons'
import { riskLabel } from './RiskBadge'

/**
 * Auto-fit, but only when the operator has not framed the view themselves.
 *
 * The previous version refit the bounds on every change to the report list, so
 * a pan or zoom was yanked back the moment the mobile app synced a new report.
 * Now: refit when the study area changes, and once when the first reports
 * arrive for that area. After that the view belongs to the user.
 */
function FitBounds({ area, reports }: { area: Area; reports: Report[] }) {
  const map = useMap()
  const fittedArea = useRef<string | null>(null)
  const fittedReports = useRef(false)

  useEffect(() => {
    if (fittedArea.current === area.id) return
    fittedArea.current = area.id
    fittedReports.current = false
    map.fitBounds(
      [
        [area.south, area.west],
        [area.north, area.east],
      ],
      { padding: [28, 28], maxZoom: 15 },
    )
  }, [map, area])

  useEffect(() => {
    if (fittedReports.current || reports.length === 0) return
    fittedReports.current = true
    map.fitBounds(
      L.latLngBounds(
        reports.map((report) => [report.latitude, report.longitude] as [number, number]),
      ),
      { padding: [48, 48], maxZoom: 16 },
    )
  }, [map, reports])

  return null
}

const LEGEND: RiskLevel[] = ['red', 'yellow', 'blue']

const LEGEND_SWATCH: Record<RiskLevel, string> = {
  red: 'bg-risk-red-solid',
  yellow: 'bg-risk-yellow-solid',
  blue: 'bg-risk-blue-solid',
}

type Props = {
  area: Area
  reports: Report[]
  selectedId: string | null
  onSelect: (id: string) => void
  showMarkers: boolean
  showHeatmap: boolean
  showHotspots: boolean
  filtered: boolean
}

export function LiveMap({
  area,
  reports,
  selectedId,
  onSelect,
  showMarkers,
  showHeatmap,
  showHotspots,
  filtered,
}: Props) {
  const { resolved } = useTheme()
  const accent = MAP_ACCENT[resolved]
  return (
    <div className="relative h-full w-full">
      <MapContainer
        center={areaCenter(area)}
        zoom={13}
        className="h-full w-full"
        scrollWheelZoom
        zoomControl
      >
        {/* Keyed on the theme: react-leaflet does not re-create the layer for a
            changed `url`, so without this the old basemap stays on screen. */}
        <TileLayer
          key={resolved}
          attribution="&copy; OpenStreetMap &copy; CARTO"
          url={TILE_URL[resolved]}
          detectRetina
        />
        <FitBounds area={area} reports={reports} />

        {/* Study-area boundary: hidden for the nationwide view. */}
        {area.id !== 'all-locations' ? (
          <Rectangle
            bounds={[
              [area.south, area.west],
              [area.north, area.east],
            ]}
            pathOptions={{
              color: accent,
              weight: 1.5,
              dashArray: '6 6',
              fillColor: accent,
              fillOpacity: resolved === 'dark' ? 0.05 : 0.03,
              interactive: false,
            }}
          />
        ) : null}

        {showHeatmap ? <HeatLayer reports={reports} /> : null}
        {showHotspots ? <HotspotLayer reports={reports} /> : null}
        {showMarkers
          ? reports.map((report) => {
              const selected = report.id === selectedId
              return (
                <Marker
                  key={report.id}
                  position={[report.latitude, report.longitude]}
                  icon={riskIcon(report.riskLevel, selected, resolved)}
                  zIndexOffset={selected ? 1000 : 0}
                  keyboard
                  title={`${riskLabel(report.riskLevel)} report`}
                  alt={`${riskLabel(report.riskLevel)} report, open detail`}
                  eventHandlers={{ click: () => onSelect(report.id) }}
                />
              )
            })
          : null}
      </MapContainer>

      {/* Area label sits top-right: top-left belongs to leaflet's zoom control. */}
      <div className="pointer-events-none absolute right-3 top-3 z-[var(--z-map-overlay)]">
        <span className="inline-flex items-center gap-2 rounded-control border border-border bg-surface/90 px-2.5 py-1.5 text-xs font-medium text-ink shadow-sm backdrop-blur-sm">
          <span
            className="h-0 w-3.5 border-t-2 border-dashed border-primary"
            aria-hidden="true"
          />
          {area.name}
        </span>
      </div>

      {/* Legend, bottom-left, clear of leaflet's attribution. Hidden on phones,
          where it would cover a third of an already-short map; the risk rows in
          the panel below carry the same colour key. */}
      <div className="pointer-events-none absolute bottom-3 left-3 z-[var(--z-map-overlay)] hidden sm:block">
        <div className="rounded-control border border-border bg-surface/90 px-2.5 py-2 shadow-sm backdrop-blur-sm">
          <ul className="flex flex-col gap-1.5">
            {LEGEND.map((level) => (
              <li key={level} className="flex items-center gap-2 text-xs text-ink-2">
                <span
                  className={`size-2.5 rounded-full ${LEGEND_SWATCH[level]}`}
                  aria-hidden="true"
                />
                {riskLabel(level)}
              </li>
            ))}
            {showHotspots ? (
              <li className="flex items-center gap-2 border-t border-border pt-1.5 text-xs text-ink-2">
                <span
                  className="size-2.5 rounded-full border border-dashed border-risk-red-solid bg-risk-red-tint"
                  aria-hidden="true"
                />
                Hotspot cluster
              </li>
            ) : null}
          </ul>
        </div>
      </div>

      {reports.length === 0 ? (
        <div className="pointer-events-none absolute inset-0 z-[var(--z-map-overlay)] grid place-items-center p-6">
          <div className="pointer-events-auto max-w-sm rounded-card border border-border bg-surface/95 p-5 text-center shadow-overlay backdrop-blur-sm">
            <span className="mx-auto mb-3 grid size-10 place-items-center rounded-full bg-sunken text-muted">
              <IconSearchOff size={20} />
            </span>
            <p className="text-md font-semibold text-ink">
              {filtered ? 'No reports match these filters' : 'No synced reports yet'}
            </p>
            <p className="mt-1.5 text-sm text-muted">
              {filtered
                ? 'Widen the date range or clear the risk filter to see more of the study area.'
                : 'Reports appear here automatically as field workers sync from the mobile app. Nothing to refresh.'}
            </p>
          </div>
        </div>
      ) : null}
    </div>
  )
}
