import { useEffect } from 'react'
import { useMap } from 'react-leaflet'
import L from 'leaflet'
import 'leaflet.heat'
import { HEAT_GRADIENT } from '../format'
import { useTheme } from '../theme'
import type { Report } from '../types'

export function HeatLayer({ reports }: { reports: Report[] }) {
  const map = useMap()
  const { resolved } = useTheme()

  useEffect(() => {
    const points: Array<[number, number, number]> = reports.map((report) => [
      report.latitude,
      report.longitude,
      report.riskLevel === 'red' ? 1 : report.riskLevel === 'yellow' ? 0.55 : 0.25,
    ])
    const layer = L.heatLayer(points, {
      radius: 26,
      blur: 20,
      maxZoom: 17,
      // Lower floor than the default, which smears a flat wash across the whole
      // study area. Dark tiles need a higher floor: the same 0.18 that reads
      // clearly on pale tiles nearly vanishes against near-black.
      minOpacity: resolved === 'dark' ? 0.3 : 0.18,
      gradient: HEAT_GRADIENT[resolved],
    })
    layer.addTo(map)
    return () => {
      map.removeLayer(layer)
    }
    // `resolved` rebuilds the canvas gradient, which leaflet.heat bakes in.
  }, [map, reports, resolved])

  return null
}
