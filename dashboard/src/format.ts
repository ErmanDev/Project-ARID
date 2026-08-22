import L from 'leaflet'
import type { RiskLevel } from './types'

import type { ResolvedTheme } from './theme'

/**
 * Map colours live here as hex, per theme, because Leaflet writes them into raw
 * SVG strings and canvas gradients — outside any stylesheet, so the CSS token
 * swap cannot reach them.
 *
 * Light values are the `-solid` end of each ramp (legible on pale tiles); dark
 * values are the lighter end (legible on dark tiles). A single set cannot do
 * both: the light pins disappear on a dark basemap.
 */
const RISK_COLOR_BY_THEME: Record<ResolvedTheme, Record<RiskLevel, string>> = {
  light: { red: '#ac3d47', yellow: '#946d1d', green: '#497d4b' },
  dark: { red: '#de5a63', yellow: '#d7a955', green: '#6fb171' },
}

/** Base hues for large translucent fills (hotspot discs, study area). */
const RISK_FILL_BY_THEME: Record<ResolvedTheme, Record<RiskLevel, string>> = {
  light: { red: '#b5555a', yellow: '#c9a66b', green: '#7c9c7c' },
  dark: { red: '#d15a61', yellow: '#c29647', green: '#62a164' },
}

export function riskColor(level: RiskLevel, theme: ResolvedTheme): string {
  return RISK_COLOR_BY_THEME[theme][level]
}

export function riskFill(level: RiskLevel, theme: ResolvedTheme): string {
  return RISK_FILL_BY_THEME[theme][level]
}

/** CARTO basemaps. Dark tiles for dark mode, or the map fights the shell. */
export const TILE_URL: Record<ResolvedTheme, string> = {
  light: 'https://basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
  dark: 'https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
}

/** Study-area boundary, and the pin keyline, per theme. */
export const MAP_ACCENT: Record<ResolvedTheme, string> = {
  light: '#4a7a8c',
  dark: '#92c7dc',
}

const PIN_OUTLINE: Record<ResolvedTheme, string> = {
  light: '#ffffff',
  // Pure white ringing a bright pin glares on dark tiles; the panel colour
  // reads as a cut-out instead.
  dark: '#1a1f22',
}

/**
 * Teardrop pin. The selected variant is drawn larger with a ring rather than
 * animated, so a live-updating map never flickers at the operator.
 */
export function riskIcon(
  level: RiskLevel,
  selected = false,
  theme: ResolvedTheme = 'light',
): L.DivIcon {
  const color = riskColor(level, theme)
  const outline = PIN_OUTLINE[theme]
  const scale = selected ? 1.25 : 1
  const w = Math.round(24 * scale)
  const h = Math.round(32 * scale)

  const ring = selected
    ? `<circle cx="12" cy="11.5" r="10.5" fill="none" stroke="${color}" stroke-opacity="0.28" stroke-width="3"/>`
    : ''

  return L.divIcon({
    className: `arid-pin${selected ? ' arid-pin--selected' : ''}`,
    iconSize: [w, h],
    iconAnchor: [w / 2, h],
    popupAnchor: [0, -h + 4],
    html: `<svg width="${w}" height="${h}" viewBox="0 0 24 32" xmlns="http://www.w3.org/2000/svg">
      ${ring}
      <path d="M12 1.5c-5.8 0-10.5 4.7-10.5 10.4C1.5 19.6 12 30.5 12 30.5S22.5 19.6 22.5 11.9C22.5 6.2 17.8 1.5 12 1.5z" fill="${color}" stroke="${outline}" stroke-width="1.75"/>
      <circle cx="12" cy="11.5" r="3.6" fill="${outline}" fill-opacity="0.92"/>
    </svg>`,
  })
}

/**
 * Heat gradients per theme. On light tiles the ramp darkens toward the peak; on
 * dark tiles it must brighten instead, or dense clusters read as holes.
 */
export const HEAT_GRADIENT: Record<ResolvedTheme, Record<number, string>> = {
  light: { 0.2: '#7fb1c4', 0.4: '#c9a66b', 0.65: '#c07a55', 1.0: '#8f2f3a' },
  dark: { 0.2: '#2f6f8a', 0.4: '#7fae8a', 0.65: '#d7a955', 1.0: '#f2707a' },
}

export function formatWhen(iso: string): string {
  const date = new Date(iso)
  if (Number.isNaN(date.getTime())) return iso
  return date.toLocaleString(undefined, {
    dateStyle: 'medium',
    timeStyle: 'short',
  })
}

export function formatAgo(date: Date | null): string {
  if (!date) return 'waiting for data'
  const seconds = Math.round((Date.now() - date.getTime()) / 1000)
  if (seconds < 8) return 'live'
  if (seconds < 60) return `${seconds}s ago`
  const minutes = Math.round(seconds / 60)
  if (minutes < 60) return `${minutes}m ago`
  const hours = Math.round(minutes / 60)
  return `${hours}h ago`
}

/** Compact relative age for list rows. */
export function formatShortAgo(iso: string): string {
  const time = new Date(iso).getTime()
  if (Number.isNaN(time)) return ''
  const minutes = Math.round((Date.now() - time) / 60000)
  if (minutes < 1) return 'just now'
  if (minutes < 60) return `${minutes}m ago`
  const hours = Math.round(minutes / 60)
  if (hours < 24) return `${hours}h ago`
  const days = Math.round(hours / 24)
  if (days < 30) return `${days}d ago`
  return `${Math.round(days / 30)}mo ago`
}
