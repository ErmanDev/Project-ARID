import type { Report, ReviewStatus, UserProfile } from '../types'
import source from '../../../assets/mock/arid_mock.json'

/**
 * Materializes the shared file at assets/mock/arid_mock.json
 * (same JSON the Flutter app seeds into Isar).
 */
type MockReportRow = {
  id: string
  userId: string
  classification: Report['classification']
  confidenceScore: number
  riskLevel: Report['riskLevel']
  latitude: number
  longitude: number
  gpsAccuracy: number
  gpsManual?: boolean
  hoursAgo: number
  pointsAwarded: number
  imageUrl?: string
  reviewStatus?: ReviewStatus
}

type MockFile = {
  version: number
  users: UserProfile[]
  reports: MockReportRow[]
}

const file = source as MockFile

function hoursAgo(hours: number): string {
  return new Date(Date.now() - hours * 60 * 60 * 1000).toISOString()
}

export const MOCK_USERS: UserProfile[] = file.users

function toReport(row: MockReportRow): Report {
  return {
    id: row.id,
    imageUrl: row.imageUrl ?? null,
    classification: row.classification,
    confidenceScore: row.confidenceScore,
    riskLevel: row.riskLevel,
    latitude: row.latitude,
    longitude: row.longitude,
    gpsAccuracy: row.gpsAccuracy,
    gpsManual: Boolean(row.gpsManual),
    capturedAt: hoursAgo(row.hoursAgo),
    userId: row.userId,
    localUserId: row.userId,
    pointsAwarded: row.pointsAwarded,
    syncStatus: 'synced',
    reviewStatus: row.reviewStatus ?? 'unreviewed',
    reviewedAt: null,
    reviewedBy: null,
  }
}

export const MOCK_REPORTS: Report[] = file.reports.map(toReport)

let reports = MOCK_REPORTS.map((item) => ({ ...item }))

export function getMockReports(): Report[] {
  return reports
}

export function updateMockReview(
  reportId: string,
  reviewStatus: ReviewStatus,
  staffUid: string,
): void {
  reports = reports.map((item) =>
    item.id === reportId
      ? {
          ...item,
          reviewStatus,
          reviewedAt: new Date().toISOString(),
          reviewedBy: staffUid,
        }
      : item,
  )
  window.dispatchEvent(new Event('arid-mock-reports'))
}
