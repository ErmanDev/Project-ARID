export type Classification = 'breeding' | 'nonBreeding'
export type RiskLevel = 'red' | 'yellow' | 'blue'
export type SyncStatus = 'pendingUpload' | 'uploading' | 'synced' | 'failed'
export type ReviewStatus = 'unreviewed' | 'reviewed' | 'actioned'

export type Report = {
  id: string
  imageUrl: string | null
  classification: Classification
  confidenceScore: number
  riskLevel: RiskLevel
  latitude: number
  longitude: number
  gpsAccuracy: number
  gpsManual: boolean
  capturedAt: string
  userId: string
  localUserId: string | null
  pointsAwarded: number
  syncStatus: SyncStatus
  reviewStatus: ReviewStatus
  reviewedAt: string | null
  reviewedBy: string | null
}

export type UserProfile = {
  id: string
  displayName: string
  totalPoints: number
  reportCount: number
}

export type Area = {
  id: string
  name: string
  south: number
  west: number
  north: number
  east: number
}

export type Filters = {
  areaId: string
  risks: RiskLevel[]
  classification: Classification | 'all'
  range: 'all' | '24h' | '7d' | '30d'
  showMarkers: boolean
  showHeatmap: boolean
  showHotspots: boolean
}
