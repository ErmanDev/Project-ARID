import L from 'leaflet'
import type { RiskLevel } from './types'

export const RISK_COLOR: Record<RiskLevel, string> = {
  red: '#B5555A',
  yellow: '#C9A66B',
  green: '#7C9C7C',
}

export function riskIcon(level: RiskLevel): L.DivIcon {
  const color = RISK_COLOR[level]
  return L.divIcon({
    className: 'arid-pin',
    iconSize: [22, 30],
    iconAnchor: [11, 30],
    popupAnchor: [0, -28],
    html: `<svg width="22" height="30" viewBox="0 0 22 30" xmlns="http://www.w3.org/2000/svg">
      <path d="M11 1C5.5 1 1 5.7 1 11.4c0 7.4 10 17.2 10 17.2s10-9.8 10-17.2C21 5.7 16.5 1 11 1z" fill="${color}" stroke="#F5F5F3" stroke-opacity="0.35" stroke-width="1"/>
      <circle cx="11" cy="11" r="3.2" fill="#F5F5F3"/>
    </svg>`,
  })
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
  if (!date) return 'waiting for live data'
  const seconds = Math.round((Date.now() - date.getTime()) / 1000)
  if (seconds < 8) return 'live'
  if (seconds < 60) return `${seconds}s ago`
  const minutes = Math.round(seconds / 60)
  if (minutes < 60) return `${minutes}m ago`
  const hours = Math.round(minutes / 60)
  return `${hours}h ago`
}

export function startOfDay(date: Date): Date {
  return new Date(date.getFullYear(), date.getMonth(), date.getDate())
}

export function hoursAgo(hours: number): Date {
  return new Date(Date.now() - hours * 60 * 60 * 1000)
}
