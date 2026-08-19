import { useEffect } from 'react'
import { MapContainer, Marker, Rectangle, TileLayer, useMap } from 'react-leaflet'
import L from 'leaflet'
import { areaCenter } from '../areas'
import { riskIcon } from '../format'
import type { Area, Report } from '../types'
import { HeatLayer } from './HeatLayer'
import { HotspotLayer } from './HotspotLayer'

function FitVisible({ area, reports }: { area: Area; reports: Report[] }) {
  const map = useMap()
  const reportKey = reports.map((item) => item.id).join('|')
  useEffect(() => {
    if (reports.length > 0) {
      const bounds = L.latLngBounds(
        reports.map((report) => [report.latitude, report.longitude] as [number, number]),
      )
      map.fitBounds(bounds, { padding: [40, 40], maxZoom: 16 })
      return
    }
    map.fitBounds(
      [
        [area.south, area.west],
        [area.north, area.east],
      ],
      { padding: [28, 28], maxZoom: 15 },
    )
  }, [map, area, reportKey, reports])
  return null
}

type Props = {
  area: Area
  reports: Report[]
  selectedId: string | null
  onSelect: (id: string) => void
  showMarkers: boolean
  showHeatmap: boolean
  showHotspots: boolean
}

export function LiveMap({
  area,
  reports,
  selectedId,
  onSelect,
  showMarkers,
  showHeatmap,
  showHotspots,
}: Props) {
  return (
    <MapContainer
      center={areaCenter(area)}
      zoom={13}
      className="h-full w-full"
      scrollWheelZoom
    >
      <TileLayer
        attribution='&copy; OpenStreetMap &copy; CARTO'
        url="https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png"
      />
      <FitVisible area={area} reports={reports} />
      <Rectangle
        bounds={[
          [area.south, area.west],
          [area.north, area.east],
        ]}
        pathOptions={{
          color: '#8eb4c2',
          weight: 2,
          fillColor: '#4A7A8C',
          fillOpacity: 0.08,
        }}
      />
      {showHeatmap ? <HeatLayer reports={reports} /> : null}
      {showHotspots ? <HotspotLayer reports={reports} /> : null}
      {showMarkers
        ? reports.map((report) => (
            <Marker
              key={report.id}
              position={[report.latitude, report.longitude]}
              icon={riskIcon(report.riskLevel)}
              zIndexOffset={report.id === selectedId ? 1000 : 0}
              eventHandlers={{ click: () => onSelect(report.id) }}
            />
          ))
        : null}
    </MapContainer>
  )
}
