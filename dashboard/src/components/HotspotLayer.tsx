import { Circle } from 'react-leaflet'
import { RISK_COLOR } from '../format'
import type { Report } from '../types'

type Hotspot = {
  key: string
  lat: number
  lng: number
  count: number
  radiusMeters: number
}

function metersBetween(
  lat1: number,
  lng1: number,
  lat2: number,
  lng2: number,
): number {
  const toRad = (value: number) => (value * Math.PI) / 180
  const dLat = toRad(lat2 - lat1)
  const dLng = toRad(lng2 - lng1)
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2
  return 2 * 6371000 * Math.asin(Math.min(1, Math.sqrt(a)))
}

export function buildHotspots(reports: Report[]): Hotspot[] {
  const buckets = new Map<string, Report[]>()
  for (const report of reports) {
    if (report.riskLevel !== 'red') continue
    const key = `${report.latitude.toFixed(3)},${report.longitude.toFixed(3)}`
    const list = buckets.get(key) ?? []
    list.push(report)
    buckets.set(key, list)
  }
  return [...buckets.entries()]
    .filter(([, list]) => list.length >= 2)
    .map(([key, list]) => {
      const lat = list.reduce((sum, item) => sum + item.latitude, 0) / list.length
      const lng = list.reduce((sum, item) => sum + item.longitude, 0) / list.length
      const span = Math.max(
        ...list.map((item) => metersBetween(lat, lng, item.latitude, item.longitude)),
        0,
      )
      return {
        key,
        lat,
        lng,
        count: list.length,
        radiusMeters: Math.max(220, span + 90) + (list.length - 2) * 40,
      }
    })
}

export function HotspotLayer({ reports }: { reports: Report[] }) {
  const hotspots = buildHotspots(reports)
  return (
    <>
      {hotspots.map((spot) => (
        <Circle
          key={`${spot.key}-halo`}
          center={[spot.lat, spot.lng]}
          radius={spot.radiusMeters * 1.28}
          pathOptions={{
            color: RISK_COLOR.red,
            weight: 2,
            dashArray: '7 9',
            fillColor: RISK_COLOR.red,
            fillOpacity: 0.08,
            interactive: false,
          }}
        />
      ))}
      {hotspots.map((spot) => (
        <Circle
          key={`${spot.key}-core`}
          center={[spot.lat, spot.lng]}
          radius={spot.radiusMeters}
          pathOptions={{
            color: RISK_COLOR.red,
            weight: 2.5,
            fillColor: RISK_COLOR.red,
            fillOpacity: 0.2,
            interactive: false,
          }}
        />
      ))}
    </>
  )
}
