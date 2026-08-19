import { formatWhen } from '../format'
import { setReviewStatus } from '../hooks'
import type { Report, ReviewStatus, UserProfile } from '../types'
import { RiskBadge } from './RiskBadge'

type Props = {
  report: Report
  reporter: UserProfile | undefined
  staffUid: string
  onClose: () => void
}

export function ReportDetail({ report, reporter, staffUid, onClose }: Props) {
  async function setStatus(status: ReviewStatus) {
    await setReviewStatus(report.id, status, staffUid)
  }

  return (
    <div className="flex h-full flex-col">
      <div className="flex items-start justify-between gap-3">
        <div>
          <h2 className="text-base font-semibold text-ink">Report detail</h2>
          <p className="text-xs text-muted">{formatWhen(report.capturedAt)}</p>
        </div>
        <button type="button" className="text-sm text-primary" onClick={onClose}>
          Close
        </button>
      </div>
      <div className="mt-3 overflow-y-auto">
        {report.imageUrl ? (
          <img
            src={report.imageUrl}
            alt="Breeding site report"
            className="mb-3 h-44 w-full rounded-xl object-cover"
          />
        ) : (
          <div className="mb-3 flex h-28 items-center justify-center rounded-xl border border-divider bg-background text-sm text-muted">
            No image URL on this synced report
          </div>
        )}
        <div className="mb-3 flex flex-wrap items-center gap-2">
          <RiskBadge level={report.riskLevel} />
          <span className="text-sm text-ink">
            {report.classification === 'breeding' ? 'Breeding site' : 'Non-breeding'}
          </span>
        </div>
        <dl className="space-y-2 text-sm">
          <Row label="Confidence" value={`${(report.confidenceScore * 100).toFixed(1)}%`} />
          <Row
            label="GPS"
            value={`${report.latitude.toFixed(5)}, ${report.longitude.toFixed(5)}`}
          />
          <Row
            label="Accuracy"
            value={
              report.gpsManual ? 'Manual pin' : `±${Math.round(report.gpsAccuracy)} m`
            }
          />
          <Row label="Reporter" value={reporter?.displayName ?? 'Community reporter'} />
          <Row label="Points" value={`${report.pointsAwarded} (from mobile)`} />
          <Row label="Sync" value={report.syncStatus} />
          <Row label="Review" value={report.reviewStatus} />
        </dl>
        <p className="mt-3 text-xs text-muted">
          Review status is the only field this dashboard writes. Classification and risk stay as
          the mobile app recorded them.
        </p>
        <div className="mt-3 grid grid-cols-3 gap-2">
          <button
            type="button"
            className="rounded-lg border border-divider px-2 py-2 text-xs text-ink"
            onClick={() => void setStatus('unreviewed')}
          >
            Unreviewed
          </button>
          <button
            type="button"
            className="rounded-lg border border-primary px-2 py-2 text-xs text-primary"
            onClick={() => void setStatus('reviewed')}
          >
            Reviewed
          </button>
          <button
            type="button"
            className="rounded-lg bg-secondary px-2 py-2 text-xs text-white"
            onClick={() => void setStatus('actioned')}
          >
            Actioned
          </button>
        </div>
      </div>
    </div>
  )
}

function Row({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex justify-between gap-4">
      <dt className="text-muted">{label}</dt>
      <dd className="text-right text-ink">{value}</dd>
    </div>
  )
}
