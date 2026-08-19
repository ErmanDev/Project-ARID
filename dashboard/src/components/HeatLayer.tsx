import { useEffect } from 'react'
import { useMap } from 'react-leaflet'
import L from 'leaflet'
import 'leaflet.heat'
import { RISK_COLOR } from '../format'
import type { Report } from '../types'

export function HeatLayer({ reports }: { reports: Report[] }) {
  const map = useMap()

  useEffect(() => {
    const points: Array<[number, number, number]> = reports.map((report) => [
      report.latitude,
      report.longitude,
      report.riskLevel === 'red' ? 1 : report.riskLevel === 'yellow' ? 0.55 : 0.25,
    ])
    const layer = L.heatLayer(points, {
      radius: 28,
      blur: 18,
      maxZoom: 17,
      minOpacity: 0.25,
      gradient: {
        0.2: RISK_COLOR.green,
        0.55: RISK_COLOR.yellow,
        0.85: RISK_COLOR.red,
      },
    })
    layer.addTo(map)
    return () => {
      map.removeLayer(layer)
    }
  }, [map, reports])

  return null
}
