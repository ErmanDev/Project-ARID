import type { Area } from './types'

/** Matches the mobile app's default study bounding box. */
export const AREAS: Area[] = [
  {
    id: 'all-locations',
    name: 'All locations',
    south: 4.5,
    west: 116.0,
    north: 21.5,
    east: 127.0,
  },
  {
    id: 'study-area',
    name: 'Primary study area (Metro Manila)',
    south: 14.55,
    west: 120.97,
    north: 14.70,
    east: 121.08,
  },
  {
    id: 'quezon-city',
    name: 'Quezon City (sample)',
    south: 14.6,
    west: 121.0,
    north: 14.76,
    east: 121.12,
  },
  {
    id: 'manila',
    name: 'City of Manila (sample)',
    south: 14.56,
    west: 120.94,
    north: 14.64,
    east: 121.02,
  },
]

export const DEFAULT_AREA_ID = 'all-locations'

export function areaById(id: string): Area {
  return AREAS.find((area) => area.id === id) ?? AREAS[0]
}

export function areaCenter(area: Area): [number, number] {
  return [(area.south + area.north) / 2, (area.west + area.east) / 2]
}

export function inArea(
  lat: number,
  lng: number,
  area: Area,
): boolean {
  return lat >= area.south && lat <= area.north && lng >= area.west && lng <= area.east
}
