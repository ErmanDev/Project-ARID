import { useEffect, useState } from 'react'
import {
  collection,
  onSnapshot,
  serverTimestamp,
  updateDoc,
  doc,
  type DocumentData,
} from 'firebase/firestore'
import { getDb } from './firebase'
import { useMockData } from './config'
import { getMockReports, MOCK_USERS, updateMockReview } from './mock/data'
import type { Classification, Report, ReviewStatus, RiskLevel, SyncStatus, UserProfile } from './types'

function asString(value: unknown, fallback = ''): string {
  return typeof value === 'string' ? value : fallback
}

function asNumber(value: unknown, fallback = 0): number {
  return typeof value === 'number' && Number.isFinite(value) ? value : fallback
}

function parseReport(id: string, data: DocumentData): Report | null {
  const lat = asNumber(data.latitude, Number.NaN)
  const lng = asNumber(data.longitude, Number.NaN)
  if (!Number.isFinite(lat) || !Number.isFinite(lng)) return null

  const classification = asString(data.classification) === 'nonBreeding'
    ? 'nonBreeding'
    : 'breeding'
  const risk = asString(data.riskLevel)
  // Legacy synced docs used "green" for non-breeding; normalize to blue.
  const riskLevel: RiskLevel =
    risk === 'red' || risk === 'yellow' || risk === 'blue'
      ? risk
      : risk === 'green'
        ? 'blue'
        : 'yellow'
  const sync = asString(data.syncStatus, 'synced')
  const syncStatus: SyncStatus =
    sync === 'pendingUpload' || sync === 'uploading' || sync === 'failed' || sync === 'synced'
      ? sync
      : 'synced'
  const review = asString(data.reviewStatus, 'unreviewed')
  const reviewStatus: ReviewStatus =
    review === 'reviewed' || review === 'actioned' || review === 'unreviewed'
      ? review
      : 'unreviewed'

  return {
    id: asString(data.id, id),
    imageUrl: asString(data.imageUrl) || asString(data.imageRemoteUrl) || null,
    classification: classification as Classification,
    confidenceScore: asNumber(data.confidenceScore),
    riskLevel,
    latitude: lat,
    longitude: lng,
    gpsAccuracy: asNumber(data.gpsAccuracy),
    gpsManual: Boolean(data.gpsManual),
    capturedAt: asString(data.capturedAt, new Date().toISOString()),
    userId: asString(data.userId),
    localUserId: asString(data.localUserId) || null,
    pointsAwarded: asNumber(data.pointsAwarded),
    syncStatus,
    reviewStatus,
    reviewedAt: asString(data.reviewedAt) || null,
    reviewedBy: asString(data.reviewedBy) || null,
  }
}

export function useReports(enabled: boolean) {
  const [reports, setReports] = useState<Report[]>([])
  const [updatedAt, setUpdatedAt] = useState<Date | null>(null)
  const [error, setError] = useState<string | null>(null)
  // Distinguishes "still waiting for the first snapshot" from "zero reports",
  // so the panel can show skeletons instead of an empty state that is wrong.
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    if (!enabled) return
    if (useMockData) {
      const apply = () => {
        setReports(getMockReports())
        setUpdatedAt(new Date())
        setError(null)
        setLoading(false)
      }
      apply()
      window.addEventListener('arid-mock-reports', apply)
      return () => window.removeEventListener('arid-mock-reports', apply)
    }
    const unsub = onSnapshot(
      collection(getDb(), 'reports'),
      (snap) => {
        const next = snap.docs
          .map((item) => parseReport(item.id, item.data()))
          .filter((item): item is Report => item !== null)
          .filter((item) => item.syncStatus === 'synced')
        setReports(next)
        setUpdatedAt(new Date())
        setError(null)
        setLoading(false)
      },
      (err) => {
        setError(err.message)
        setLoading(false)
      },
    )
    return unsub
  }, [enabled])

  return { reports, updatedAt, error, loading }
}

export function useUsers(enabled: boolean) {
  const [users, setUsers] = useState<UserProfile[]>([])

  useEffect(() => {
    if (!enabled) return
    if (useMockData) {
      setUsers(MOCK_USERS)
      return
    }
    const unsub = onSnapshot(collection(getDb(), 'users'), (snap) => {
      setUsers(
        snap.docs.map((item) => {
          const data = item.data()
          return {
            id: item.id,
            displayName: asString(data.displayName, 'Field worker'),
            totalPoints: asNumber(data.totalPoints),
            reportCount: asNumber(data.reportCount),
          }
        }),
      )
    })
    return unsub
  }, [enabled])

  return users
}

export async function setReviewStatus(
  reportId: string,
  reviewStatus: ReviewStatus,
  staffUid: string,
): Promise<void> {
  if (useMockData) {
    updateMockReview(reportId, reviewStatus, staffUid)
    return
  }
  await updateDoc(doc(getDb(), 'reports', reportId), {
    reviewStatus,
    reviewedAt: new Date().toISOString(),
    reviewedBy: staffUid,
    updatedAt: serverTimestamp(),
  })
}

export function useOnline() {
  const [online, setOnline] = useState(
    typeof navigator === 'undefined' ? true : navigator.onLine,
  )
  useEffect(() => {
    const on = () => setOnline(true)
    const off = () => setOnline(false)
    window.addEventListener('online', on)
    window.addEventListener('offline', off)
    return () => {
      window.removeEventListener('online', on)
      window.removeEventListener('offline', off)
    }
  }, [])
  return online
}
