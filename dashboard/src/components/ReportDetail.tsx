import { useEffect, useState } from 'react'
import { writeErrorMessage } from '../errors'
import { formatShortAgo, formatWhen } from '../format'
import { setReviewStatus } from '../hooks'
import type { Report, ReviewStatus, SyncStatus, UserProfile } from '../types'
import { IconClose, IconImageOff } from './icons'
import { RiskBadge } from './RiskBadge'
import { Alert, Segmented, type SegmentOption } from './ui'

type Props = {
  report: Report
  reporter: UserProfile | undefined
  staffUid: string
  onClose: () => void
}

const SYNC_LABEL: Record<SyncStatus, string> = {
  pendingUpload: 'Pending upload',
  uploading: 'Uploading',
  synced: 'Synced',
  failed: 'Failed',
}

const REVIEW_OPTIONS: SegmentOption<ReviewStatus>[] = [
  { value: 'unreviewed', label: 'Unreviewed' },
  { value: 'reviewed', label: 'Reviewed' },
  { value: 'actioned', label: 'Actioned' },
]

export function ReportDetail({ report, reporter, staffUid, onClose }: Props) {
  // Optimistic review state: the Firestore snapshot round-trip is visible on a
  // slow connection, and a control that ignores the click feels broken.
  const [pending, setPending] = useState<ReviewStatus | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [imageFailed, setImageFailed] = useState(false)

  useEffect(() => {
    setPending(null)
    setError(null)
    setImageFailed(false)
  }, [report.id])

  const shown = pending ?? report.reviewStatus

  async function apply(status: ReviewStatus) {
    if (status === shown) return
    setPending(status)
    setError(null)
    try {
      await setReviewStatus(report.id, status, staffUid)
    } catch (err) {
      setPending(null)
      setError(writeErrorMessage(err))
    }
  }

  // Clear the optimistic value once the live snapshot agrees.
  useEffect(() => {
    if (pending && report.reviewStatus === pending) setPending(null)
  }, [pending, report.reviewStatus])

  const confidence = Math.round(report.confidenceScore * 100)

  return (
    <div className="flex flex-col">
      <div className="flex items-start justify-between gap-3 border-b border-border px-4 py-3">
        <div className="min-w-0">
          <h2 className="text-md font-semibold text-ink">Report detail</h2>
          <p className="mt-0.5 truncate text-xs text-muted">
            <time dateTime={report.capturedAt}>{formatWhen(report.capturedAt)}</time>
            <span aria-hidden="true"> &middot; </span>
            {formatShortAgo(report.capturedAt)}
          </p>
        </div>
        <button
          type="button"
          onClick={onClose}
          aria-label="Close report detail"
          className="tap -mr-1 -mt-1 grid size-8 shrink-0 place-items-center rounded-control text-muted transition-colors duration-(--duration-fast) ease-(--ease-out-quart) hover:bg-sunken hover:text-ink"
        >
          <IconClose size={16} />
        </button>
      </div>

      <div className="px-4 py-3.5">
        {report.imageUrl && !imageFailed ? (
          <img
            src={report.imageUrl}
            alt={`Field photo of the reported ${
              report.classification === 'breeding' ? 'breeding site' : 'inspected container'
            }`}
            loading="lazy"
            onError={() => setImageFailed(true)}
            /* Fixed ratio reserves the box before the bytes land, so the panel
               below never jumps. */
            className="aspect-[4/3] w-full rounded-card border border-border bg-sunken object-cover"
          />
        ) : (
          <div className="flex aspect-[4/3] w-full flex-col items-center justify-center gap-2 rounded-card border border-dashed border-border bg-sunken text-muted">
            <IconImageOff size={22} />
            <p className="max-w-[26ch] text-center text-xs">
              {imageFailed
                ? 'The Cloudinary image could not be loaded.'
                : 'This synced report carries no photo URL.'}
            </p>
          </div>
        )}

        <div className="mt-3.5 flex flex-wrap items-center gap-2">
          <RiskBadge level={report.riskLevel} size="sm" />
          <span className="rounded-full border border-border bg-sunken px-2 py-0.5 text-xs font-medium text-ink-2">
            {report.classification === 'breeding' ? 'Breeding site' : 'Non-breeding'}
          </span>
        </div>

        <div className="mt-3.5">
          <div className="flex items-baseline justify-between text-xs">
            <span className="text-muted">Model confidence</span>
            <span data-numeric className="font-semibold text-ink">
              {confidence}%
            </span>
          </div>
          <div
            className="mt-1.5 h-1.5 overflow-hidden rounded-full bg-sunken"
            role="meter"
            aria-valuenow={confidence}
            aria-valuemin={0}
            aria-valuemax={100}
            aria-label="On-device model confidence"
          >
            <div
              className="h-full rounded-full bg-primary transition-[width] duration-(--duration-slow) ease-(--ease-out-quart)"
              style={{ width: `${confidence}%` }}
            />
          </div>
        </div>

        <dl className="mt-3.5 divide-y divide-border border-y border-border text-base">
          <Row
            label="GPS"
            value={`${report.latitude.toFixed(5)}, ${report.longitude.toFixed(5)}`}
            numeric
          />
          <Row
            label="Accuracy"
            value={
              report.gpsManual ? 'Manual pin' : `±${Math.round(report.gpsAccuracy)} m`
            }
            numeric={!report.gpsManual}
          />
          <Row label="Reporter" value={reporter?.displayName ?? 'Community reporter'} />
          <Row label="Points awarded" value={String(report.pointsAwarded)} numeric />
          <Row label="Sync" value={SYNC_LABEL[report.syncStatus]} />
        </dl>

        <div className="mt-4">
          <div className="mb-2 flex items-baseline justify-between gap-2">
            <h3 className="text-sm font-semibold text-ink">Review status</h3>
            {report.reviewedAt ? (
              <span className="text-xs text-muted">
                updated {formatShortAgo(report.reviewedAt)}
              </span>
            ) : null}
          </div>
          <Segmented
            label="Set review status"
            value={shown}
            options={REVIEW_OPTIONS}
            onChange={(next) => void apply(next)}
            className="w-full [&>button]:flex-1 [&>button]:justify-center"
          />
          <p className="mt-2 text-xs text-muted">
            The only field this dashboard writes. Classification and risk stay as
            the mobile app recorded them.
          </p>
          {error ? (
            <Alert tone="error" live className="mt-2">
              {error}
            </Alert>
          ) : null}
        </div>
      </div>
    </div>
  )
}

function Row({
  label,
  value,
  numeric = false,
}: {
  label: string
  value: string
  numeric?: boolean
}) {
  return (
    <div className="flex items-baseline justify-between gap-4 py-2">
      <dt className="shrink-0 text-muted">{label}</dt>
      <dd
        {...(numeric ? { 'data-numeric': true } : {})}
        className="min-w-0 truncate text-right text-ink"
      >
        {value}
      </dd>
    </div>
  )
}
