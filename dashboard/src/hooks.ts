import { useEffect, useState } from 'react'
import {
  collection,
  onSnapshot,
  serverTimestamp,
  updateDoc,
  deleteDoc,
  doc,
  type DocumentData,
} from 'firebase/firestore'
import { getDb } from './firebase'
import { useMockData } from './config'
import { readErrorMessage } from './errors'
import { getMockReports, MOCK_USERS, updateMockReview } from './mock/data'
import type {
  AccountStatus,
  Classification,
  Report,
  ReviewStatus,
  RiskLevel,
  SyncStatus,
  UserProfile,
} from './types'

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
  // Mobile syncs non-breeding as "green"; legacy docs may still say "blue".
  const riskLevel: RiskLevel =
    risk === 'red' || risk === 'yellow'
      ? risk
      : risk === 'green' || risk === 'blue'
        ? 'green'
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
        setError(readErrorMessage(err))
        setLoading(false)
      },
    )
    return unsub
  }, [enabled])

  return { reports, updatedAt, error, loading }
}

function asTimestamp(value: unknown): string | null {
  if (typeof value === 'string') return value
  if (value && typeof value === 'object' && 'toDate' in value) {
    const date = (value as { toDate: () => Date }).toDate()
    return Number.isNaN(date.getTime()) ? null : date.toISOString()
  }
  return null
}

const STATUSES: readonly AccountStatus[] = ['pending', 'verified', 'rejected']

export function parseUserProfile(id: string, data: DocumentData): UserProfile {
  const firstName = asString(data.firstName)
  const middleName = asString(data.middleName)
  const lastName = asString(data.lastName)
  const built = [firstName, middleName ? `${middleName.charAt(0)}.` : '', lastName]
    .filter(Boolean)
    .join(' ')
  const status = STATUSES.find((value) => value === data.status) ?? 'pending'
  return {
    id,
    username: asString(data.username),
    displayName: asString(data.displayName) || built || asString(data.username, 'Staff'),
    firstName,
    middleName,
    lastName,
    birthDate: asString(data.birthDate),
    role: data.role === 'admin' ? 'admin' : 'staff',
    status,
    createdAt: asTimestamp(data.createdAt),
    reviewedAt: asTimestamp(data.reviewedAt),
    reviewedBy: typeof data.reviewedBy === 'string' ? data.reviewedBy : null,
    totalPoints: asNumber(data.totalPoints),
    reportCount: asNumber(data.reportCount),
    // The mobile app writes this on every upsert, but documents synced by
    // older builds will not have it. Absent means "unknown", which is not the
    // same as "none verified".
    verifiedPoints:
      typeof data.verifiedPoints === 'number' && Number.isFinite(data.verifiedPoints)
        ? data.verifiedPoints
        : null,
  }
}

export function useUsers(enabled: boolean) {
  const [users, setUsers] = useState<UserProfile[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    if (!enabled) return
    if (useMockData) {
      setUsers(MOCK_USERS)
      setLoading(false)
      return
    }
    const unsub = onSnapshot(
      collection(getDb(), 'users'),
      (snap) => {
        setUsers(snap.docs.map((item) => parseUserProfile(item.id, item.data())))
        setError(null)
        setLoading(false)
      },
      (err) => {
        setError(readErrorMessage(err))
        setLoading(false)
      },
    )
    return unsub
  }, [enabled])

  return { users, loading, error }
}

/** Verifies, rejects, or revokes (back to rejected) an account. Admins only. */
export async function setAccountStatus(
  userId: string,
  status: AccountStatus,
  adminUid: string,
): Promise<void> {
  if (useMockData) return
  await updateDoc(doc(getDb(), 'users', userId), {
    status,
    reviewedAt: serverTimestamp(),
    reviewedBy: adminUid,
    updatedAt: serverTimestamp(),
  })
}

/**
 * Removes a staff registration. The person can register again with the same
 * username and password, which recreates their pending request.
 */
export async function deleteAccount(userId: string): Promise<void> {
  if (useMockData) return
  await deleteDoc(doc(getDb(), 'users', userId))
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
